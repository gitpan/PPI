package PPI::Token::QuoteLike::Command;

# Back Ticks

use strict;
use UNIVERSAL 'isa';
use base 'PPI::Token::_QuoteEngine::Simple',
         'PPI::Token::QuoteLike';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.841';
}

1;
