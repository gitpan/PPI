package PPI::Token::Quote::Simple;

# Simple quote engine

use strict;
use base 'PPI::Token::Quote';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.812';
}





sub new {
	my $class = shift;
	my $seperator = shift or return undef;

	# Create a new token containing the seperator
	my $self = $class->SUPER::new( $seperator ) or return undef;
	$self->{seperator} = $seperator;

	$self;
}

sub _fill {
	my $class = shift;
	my $t = shift;
	my $self = $t->{token} or return undef;

	# Scan for the end seperator
	my $string = $self->_scan_for_unescaped_character( $t, $self->{seperator} );
	return undef unless defined $string;
	if ( ref $string ) {
		# End of file
		$self->{content} .= $$string;
		return 0;
	} else {
		# End of string
		$self->{content} .= $string;
		return $self;
	}
}

sub get_string {
	my $self = shift;
	substr( $self->{content}, 1, length($self->{content}) - 2 );
}

1;
