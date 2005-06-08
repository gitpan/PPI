package PPI::Token::Label;

=pod

=head1 NAME

PPI::Token::Label - Token class for a statement label

=head1 INHERITANCE

  PPI::Token::Label
  isa PPI::Token
      isa PPI::Element

=head1 DESCRIPTION

A label is an identifier attached to a line or statements, to allow for
various types of flow control. For example, a loop might have a label
attached so that a C<last> or C<next> flow control statement can be used
from multiple levels below to reference the loop directly.

=head1 METHODS

There are no additional methods beyond those provided by the parent
L<PPI::Token> and L<PPI::Element> classes.

Got any ideas for methods? Submit a report to rt.cpan.org!

=cut

use strict;
use UNIVERSAL 'isa';
use base 'PPI::Token';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.990';
}

1;

=pod

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main module

=head1 AUTHOR

Adam Kennedy, L<http://ali.as/>, cpan@ali.as

=head1 COPYRIGHT

Copyright (c) 2004 - 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
