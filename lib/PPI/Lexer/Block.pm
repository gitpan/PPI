package PPI::Lexer::Block;

# A PPI::Lexer::Block represent a lexical block of code.
# In PPI::Lexer this is used to represent a block of any type,
# including {} () and [] types. This is done for simplicity.

use strict;
use UNIVERSAL 'isa';
use base 'PPI::Lexer::Element';

# Create the type map
use vars qw{$typeMap};
BEGIN {
	$typeMap = {
		'[' => '[]',
		'{' => '{}',
		'(' => '()'
		};
}

sub new {
	my $class = shift;
	
	# Get a new Element object, and add our new bits
	my $self = $class->SUPER::new();
	$self->{type} = undef;
	$self->{elements} = [];
	$self->{tokens} = {};

	# Handle the special top case
	if ( $_[0] eq 'top' ) {
		$self->{type} = 'top';
		return $self;
	}
	
	# Check the open token
	my $openToken = shift;
	my $content = $openToken->{content};
	unless ( UNIVERSAL::isa( $openToken, 'PPI::Lexer::Token' ) ) {
		return $self->_error( "You did not pass an open token." );
	}
	unless ( $openToken->{class} eq 'Structure' ) {
		return $self->_error( "Must create block with a structure token" );
	}
	unless ( $PPI::Lexer::openOrClose->{ $content } eq 'open' ) {
		return $self->_error( "Token is not an opening brace" );
	}
	
	# Set the type and open token
	unless ( $self->set_type( $typeMap->{ $content } ) ) {
		return $self->_error( "Error setting type during Block creation" );
	}
	unless ( $self->set_open_token( $openToken ) ) {
		return $self->_error( "Error setting open Token" );
	}
	
	return $self;
}





#####################################################################
# Basic getters and setters

use vars qw{$valid};
BEGIN {
	# Define the allowable data values
	$valid = {
		'{}' => {
			Conditional => 1,
			AnonymousSub => 1,
			HashKey => 1,
			Scope => 1,
			TimingBlock => 1,
			Sub => 1,
			MapGrepSort => 1,
			AnonHashRef => 1,
			CastSelector => 1,
			ForBlock => 1,
			},
		'[]' => {
			ArrayKey => 1,
			AnonArrayRef => 1,
			},
		'()' => {
			Condition => 1,
			Precedence => 1,
			Arguments => 1,
			List => 1,
			ForCondition => 1,
			},
		'top' => 1,
		};
}

sub set_type {
	my $self = shift;
	my $type = shift;
	unless ( $valid->{$type} ) {
		return $self->_error( "'$type' is not a valid block type" );
	}
	$self->{type} = $type;
	return 1;
}
sub get_type { $_[0]->{type} }
sub type { $_[0]->{type} }

sub set_class {
	my $self = shift;
	my $class = shift;
	unless ( $valid->{ $self->{type} }->{$class} ) {
		return $self->_error( "Bad class '$class' for block type '$self->{type}'" );
	}
	$self->{class} = $class;
	return 1;
}

sub get_open_token { $_[0]->{tokens}->{open} }
sub set_open_token {
	my $self = shift;
	my $token = shift;
	unless ( UNIVERSAL::isa( $token, 'PPI::Lexer::Token' ) ) {
		return $self->_error( "Cannot set open token to a non PPI::Lexer::Token" );
	}
	$self->{tokens}->{open} = $token;
	return 1;
}

sub get_close_token { $_[0]->{tokens}->{close} }
sub set_close_token {
	my $self = shift;
	my $token = shift;
	unless ( UNIVERSAL::isa( $token, 'PPI::Lexer::Token' ) ) {
		return $self->_error( "->closeBlock was not passed a PPI::Lexer::Token" );
	}
	unless ( $token->class eq 'Structure' ) {
		return $self->_error( "Cannot close a block with a non Structure token" );
	}
	my $required = $PPI::Lexer::matching->{ $self->{tokens}->{open}->{content} } or return undef;
	unless ( $token->{content} eq $required ) {
		return $self->_error( "Cannot close '$self->{tokens}->{open}->{content}' block with "
			. "'$token->{content}', expected '$required'" );
	}
	$self->{tokens}->{close} = $token;
	return 1;
}





#####################################################################
# Manipulation

# Blocks cannot contain significant tokens directly, they can only contain
# PPI::Lexer::Element objects
sub add_element {
	my $self = shift;
	my $Element = shift;
	unless ( UNIVERSAL::isa( $Element, 'PPI::Lexer::Element' ) ) {
		return $self->_error( "You passed a non-element to add_element" );
	}
	
	# Add the element to the array
	push @{ $self->{elements} }, $Element;
	
	# Set the element's parent as us
	$Element->set_parent( $self );
	return 1;
}

# The only thing other than an element that can be added to a block is either
# direct whitespace, or a comment.
sub add_token {
	my $self = shift;
	my $Token = shift;
	unless ( isa( $Token, 'PPI::Lexer::Token' ) ) {
		return $self->_error( "You passed a non-token to add_token" );
	}
	push @{ $self->{elements} }, $Token;
	return 1;
}

# Remove all sub elements
sub clear {
	my $self = shift;
	foreach my $child ( @{ $self->{elements} } ) {
		if ( isa( $child, 'PPI::Lever::Element' ) ) {
			# Recurse down the blocks so we don't leak memory
			$child->removeElement;
		}
	}
	$self->{elements} = [];
	return 1;
}

# Detach a block from it's parent
sub detach {
	my $self = shift;
	$self->clear;
	delete $self->{parent};
	return 1;
}






#####################################################################
# Primarmy methods

# Turn the block into an array ref of tokens
sub flatten {
	[ 
	map { 
		exists $_->{elements} 
			? ( $_->{tokens}->{open} || (), @{ $_->flatten }, $_->{tokens}->{close} || () )
			: $_ 
	} 
	@{ $_[0]->{elements} }
	]
}

# Remove all whitespace
sub remove_whitespace {
	my $self = shift;
	my @cleaned = ();
	foreach my $element ( @{ $self->{elements} } ) {
		# Recurse
		if ( exists $element->{elements} ) {
			$element->remove_whitespace;
			push @cleaned, $element;
			next;
		}
		
		# Ditch Base tokens
		next if $element->{class} eq 'Base';
		
		# Remove whitespace from comments
		if ( $element->{class} eq 'Comment' ) {
			chomp $element->{content};
			$element->{content} =~ s/^\s+//;
			$element->{content} =~ s/\s+$//;			
		}
		
		# Add to new array
		push @cleaned, $element;
	}
	
	# Update array and return
	$self->{elements} = \@cleaned;
	return 1;
}

# The block version of is_a can check for both type and class context
# sensitively
sub is_a {
	my $self = shift;
	foreach my $check ( @_ ) {
		if ( $check eq '{}' or $check eq '[]' or $check eq '()' ) {
			return 0 unless $self->{type} eq $check;
		} else {
			return 0 unless $self->{class} eq $check;
		}
	}
	return 1;
}

1;