package PPI::Lexer;

# The PPI::Lexer package does some rudimentary structure analysis of
# the token stream produced by the tokenizer.

use strict;
use PPI ();
use PPI::Token ();
use PPI::Document ();
use base 'PPI::Common';

use vars qw{$VERSION};
BEGIN {
	$VERSION = "0.7";
}





# Create a new lexer for a file
sub new {
	my $class = shift;
	my $filename = (-f $_[0] and -r $_[0]) ? shift : return undef;

	# Create and return the object
	return bless {
		# Data attributes
		filename   => $filename,
		};
}





#####################################################################
# Accessor methods

sub filename { $_[0]->{filename} }
sub loaded { $_[0]->{loaded} }
sub lexed { $_[0]->{lexed} }





#####################################################################
# Main functional methods

# Load the file
sub load {
	my $self = shift;

	# Are we already loaded or lexed?
	$self->{document} || $self->{tokenizer} and return 1;

	# Load the raw source
	$/ = undef;
	open( FILE, $self->{filename} ) or return undef;
	my $source = <FILE>;
	return undef unless defined $source;
	close FILE or return undef;

	# Create the tokenizer
	$self->{tokenizer} = PPI::Tokenizer->new( source => $source ) or return undef;

	return 1;
}

# Lex the file, loading if needed
sub lex {
	my $self = shift;
	return 1 if $self->{document};
	$self->{tokenizer} or $self->load() or return undef;

	# Create the lexer document
	$self->{document} = PPI::Document->new() or return undef;

	# Lex the file
	$self->{document}->lex( $self->{tokenizer} ) or return undef;

	# Delete the tokenizer when we are finished with it,
	# for memory garbage collecting reasons.
	delete $self->{tokenizer};

	return 1;
}

# Get the document, lexing if needed
sub Document {
	my $self = shift;
	$self->{document} or $self->lex() or return undef;
	return $self->{document};
}

1;
