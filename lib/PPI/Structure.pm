package PPI::Structure;

# Implements a structure

use strict;
use UNIVERSAL 'isa';
use PPI ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.801';
	@PPI::Structure::ISA = 'PPI::ParentElement';
}





sub new {
	my $class = shift;
	my $token = (isa( $_[0], 'PPI::Token' ) && $_[0]->_opens_structure)
		? shift : return undef;

	# Create the object
	return bless {
		elements => [],
		start    => $token,
		}, $class;
}





#####################################################################
# Accessors

sub start  { $_[0]->{start} }
sub finish { $_[0]->{finish} }





#####################################################################
# Main functional methods

sub lex {
	my $self = shift;

	# Get the tokenizer
	$self->{tokenizer} = isa( $_[0], 'PPI::Tokenizer' )
		? shift : return undef;

	# Start the processing loop
	my $token;
	while ( $token = $self->{tokenizer}->get_token ) {
		# Is this a direct type token
		unless ( $token->significant ) {
			$self->add_element( $token );
			next;
		}

		# For anything other than a structural element
		unless ( $token->class eq 'PPI::Token::Structure' ) {
			# Create a new statement
			my $Statement = PPI::Statement->new( $token ) or return undef;

			# Pass the lex control to it
			$Statement->lex( $self->{tokenizer} ) or return undef;

			# Add the completed statement to our elements
			$self->add_element( $Statement );
			next;
		}

		# Is this the opening of a structure?
		if ( $token->_opens_structure ) {
			# Create the new block
			my $Structure = PPI::Structure->new( $token ) or return undef;

			# Pass the lex control to it
			$Structure->lex( $self->{tokenizer} ) or return undef;

			# Add the completed block to our elements
			$self->add_element( $Structure );
			next;
		}

		# Is this the close of a structure ( which would be an error )
		if ( $token->_closes_structure ) {
			# Is this OUR closing structure
			if ( $token->content eq $self->{start}->_matching_brace ) {
				# Add and close
				$self->{finish} = $token;
				return $self->_clean( 1 );
			}

			# Unexpected close... error
			return undef;
		}

		# It's a semi-colon on it's own
		# We call this a null statement
		my $Statement = PPI::Statement->new( $token ) or return undef;
		$self->add_element( $Statement );
	}

	# Is this an error
	return undef unless defined $token;

	# No, it's the end of file
	$self->_clean( 1 );
}





#####################################################################
# Tools

# Like the token method ->content, get our merged contents.
# This will recurse downwards through everything
sub content {
	my $self = shift;
	return join '',
		map { $_->content }
		grep { $_ }
		( $self->{start}, @{$self->{elements}}, $self->{finish} );
}

1;