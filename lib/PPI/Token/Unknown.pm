package PPI::Token::Unknown;

# This large, seperate class is used when we have a limited
# number of characters that could yet mean a variety of
# different things.
#
# All the unknown cases are character by character problems,
# so this class only needs to implement _on_char()

use strict;
use base 'PPI::Token';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.801';
}





sub _on_char {
	my $t = $_[1];                              # Tokenizer object
	my $c = $t->{token}->{content};             # Current token contents
	$_ = substr( $t->{line}, $t->{line_cursor}, 1 );  # Current character


	# Now, we split on the different values of the current content


	if ( $c eq '*' ) {
		if ( /[\w:]/ ) {
			# Symbol
			return $t->_set_token_class( 'Symbol' ) ? 1 : undef;
		}

		if ( $_ eq '{' or $_ eq '$' ) {
			# GLOB cast
			$t->_set_token_class( 'Cast' ) or return undef;
			return $t->_finalize_token->_on_char( $t );
		}

		$t->_set_token_class( 'Operator' ) or return undef;
		return $t->_finalize_token->_on_char( $t );



	} elsif ( $c eq '$' ) {
		if ( /[a-z_]/i ) {
			# Symbol
			return $t->_set_token_class( 'Symbol' ) ? 1 : undef;
		}

		if ( $PPI::Token::Magic::magic{ $c . $_ } ) {
			# Magic variable
			return $t->_set_token_class( 'Magic' ) ? 1 : undef;
		}

		# Must be a cast
		$t->_set_token_class( 'Cast' ) or return undef;
		return $t->_finalize_token->_on_char( $t );



	} elsif ( $c eq '@' ) {
		if ( /[\w:]/ ) {
			# Symbol
			return $t->_set_token_class( 'Symbol' ) ? 1 : undef;
		}

		if ( /-+/ ) {
			# Magic variable
			return $t->_set_token_class( 'Magic' ) ? 1 : undef;
		}

		# Must be a cast
		$t->_set_token_class( 'Cast' ) or return undef;
		return $t->_finalize_token->_on_char( $t );



	} elsif ( $c eq '%' ) {
		# Is it a symbol?
		if ( /[\w:]/ ) {
			return $t->_set_token_class( 'Symbol' ) ? 1 : undef;
		}

		if ( /[\$@%{]/ ) {
			# It's a cast
			$t->_set_token_class( 'Cast' ) or return undef;
			return $t->_finalize_token->_on_char( $t );

		}

		# Probably the mod operator
		$t->_set_token_class( 'Operator' ) or return undef;
		return $t->{class}->_on_char( $t );



	} elsif ( $c eq '&' ) {
		# Is it a symbol
		if ( /[\w:]/ ) {
			return $t->_set_token_class( 'Symbol' ) ? 1 : undef;
		}

		if ( /[\$@%{]/ ) {
			# The ampersand is a cast
			$t->_set_token_class( 'Cast' ) or return undef;
			return $t->_finalize_token->_on_char( $t );
		}

		# Probably the binary and operator
		$t->_set_token_class( 'Operator' ) or return undef;
		return $t->{class}->_on_char( $t );



	} elsif ( $c eq '-' ) {
		if ( /\d/o ) {
			# Number
			return $t->_set_token_class( 'Number' ) ? 1 : undef;
		}

		if ( /[a-zA-Z]/ ) {
			return $t->_set_token_class( 'DashedBareword' ) ? 1 : undef;
		}

		# The numeric negative operator
		$t->_set_token_class( 'Operator' ) or return undef;
		return $t->{class}->_on_char( $t );



	} elsif ( $c eq ':' ) {
		if ( $_ eq ':' ) {
			# ::foo style bareword
			return $t->_set_token_class( 'Bareword' ) ? 1 : undef;
		}

		# Second half of the ?: trinary operator
		$t->_set_token_class( 'Operator' ) or return undef;
		return $t->{class}->_on_char( $t );



	}

	### erm...
	die 'Unknown value in PPI::Token::Unknown token';
}

1;