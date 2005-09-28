package PPI::Token::QuoteLike::Command;

=pod

=head1 NAME

PPI::Token::QuoteLike::Command - The command quote-like operator

=head1 INHERITANCE

  PPI::Token::QuoteLike::Command
  isa PPI::Token::QuoteLike
      isa PPI::Token
          isa PPI::Element

=head1 DESCRIPTION

A C<PPI::Token::QuoteLike::Command> object represents a command output
capturing quote-like operator.

=head1 METHODS

There are no methods available for C<PPI::Token::QuoteLike::Command>
beyond those provided by the parent L<PPI::Token::QuoteLike>, L<PPI::Token>
and L<PPI::Element> classes.

Got any ideas for methods? Submit a report to rt.cpan.org!

=cut

use strict;
use base 'PPI::Token::_QuoteEngine::Full',
         'PPI::Token::QuoteLike';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.101';
}

1;

=pod

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main module

=head1 AUTHOR

Adam Kennedy, L<http://ali.as/>, cpan@ali.as

=head1 COPYRIGHT

Copyright (c) 2001 - 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
