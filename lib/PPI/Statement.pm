package PPI::Statement;

=pod

=head1 NAME

PPI::Statement - The base class for perl statements

=head1 INHERITANCE

  PPI::Base
  \--> PPI::Element
       \--> PPI::Node
            \--> PPI::Statement

=head1 DESCRIPTION

PPI::Statement is the root class for all Perl statements. This includes (from
L<perlsyn|perlsyn>) "Declarations", "Simple Statements" and "Compound
Statements".

The class PPI::Statement itself represents a "Simple Statement" as defined
in the L<perlyn|perlsyn> manpage.

=head1 METHODS

PPI::Statement itself has very few methods. Most of the time, you will be
working with the more generic L<PPI::Element|PPI::Element> or
L<PPI::Node|PPI::Node> methods, or one of the methods that are
subclass-specific.

=cut

use strict;
use UNIVERSAL 'isa';
use base 'PPI::Node';
use PPI ();
use PPI::Statement::Sub       ();
use PPI::Statement::Include   ();
use PPI::Statement::Package   ();
use PPI::Statement::Variable  ();
use PPI::Statement::Compound  ();
use PPI::Statement::Scheduled ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.830';
}

# "Normal" statements end at a statement terminator ;
# Some are not, and need the more rigorous _statement_continues to see
# if we are at an implicit statement boundary.
sub __LEXER__normal { 1 }





#####################################################################
# Constructor

sub new {
	my $class = ref $_[0] ? ref shift : shift;
	
	# Create the object
	my $self = bless { 
		children => [],
		}, $class;

	# If we have been passed an initial token, add it
	if ( isa(ref $_[0], 'PPI::Token') ) {
		$self->__add_element(shift);
	}

	$self;
}

=pod

=head2 label

One factor common to most (all?) statements is their ability to be labelled.

The C<label> method returns the label for a statement, if one has been
defined, but without the trailing colon. Take the following example

  MYLABEL: while ( 1 .. 10 ) { last MYLABEL if $_ > 5 }

For the above statement, the C<label> method would return 'MYLABEL'.

Returns false if the statement does not have a label.

=cut

sub label {
	my $first = shift->schild(1);
	isa($first, 'PPI::Token::Label')
		? substr($first, 0, length($first) - 1)
		: '';
}

=pod

=head1 STATEMENT CLASSES

Please note that unless documented themselves, these classes are yet to be
frozen/finalised. Names may change slightly or be added or removed.

=head2 L<PPI::Statement::Scheduled>

This covers all "scheduled" blocks, chunks of code that are executed
seperately from the main body of the code, at a particular time. This
includes all C<BEGIN>, C<CHECK>, C<INIT> and C<END> blocks.

=head2 L<PPI::Statement::Package>

A package declaration, as defined in L<perlfunc|perlfunc/package>.

=head2 PPI::Statement::Include

A statement that loads or unloads another module.

This includes 'use', 'no', and 'require' statements.

=head2 L<PPI::Statement::Sub>

A named subroutine declaration, or forward declaration

=head2 PPI::Statement::Variable

A variable declaration statement. This could be either a straight
declaration or also be an expression.

This includes all 'my', 'local' and 'out' statements.

=head2 PPI::Statement::Compound

This covers the whole family of 'compound' statements, as described in
L<perlsyn|perlsyn>.

This includes all statements starting with 'if', 'unless', 'for', 'foreach'
and 'while'. Note that this does NOT include 'do', as it is treated
differently.

All compound statements have implicit ends. That is, they do not end with
a ';' statement terminator.

=head2 PPI::Statement::Break

A statement that breaks out of a structure.

This includes all of 'redo', 'next', 'last' and 'return' statements.

=head2 PPI::Statement::Data

A special statement which encompasses an entire __DATA__ block, including
the inital '__DATA__' token itself and the entire contents.

=head2 PPI::Statement::End

A special statement which encompasses an entire __END__ block, including
the intial '__END__' token itself and the entire contents, including any
parsed PPI::Token::POD that may occur in it.

=head2 PPI::Statement::Expression

PPI::Statement::Expression is a little more speculative, and is intended
to help represent the special rules relating to "expressions" such as in:

  # Several examples of expression statements
  
  # Boolean conditions
  if ( expression ) { ... }
  
  # Lists, such as for arguments
  Foo->bar( expression )

=head2 PPI::Statement::Null

A null statement is a special case for where we encounter two consecutive
statement terminators. ( ;; )

The second terminator is given an entire statement of it's own, but one
that serves no purpose. Hence a 'null' statement.

Theoretically, assuming a correct parsing of a perl file, all null statements
are supurfluous and should be able to be removed without damage to the file.

But don't do that, in case PPI has parsed something wrong.

=head2 PPI::Statement::UnmatchedBrace

Because PPI is intended for use when parsing incorrect or incomplete code,
the problem arises of what to do with a stray closing brace.

Rather than die, it is allocated it's own "unmatched brace" statement,
which really means "unmatched closing brace". An unmatched open brace at the
end of a file would become a structure with no contents and no closing brace.

If the document loaded is intented to be correct and valid, finding a
PPI::Statement::UnmatchedBrace in the PDOM is generally indicative of a
misparse.

=head2 PPI::Statement::Unknown

This is used temporarily mid-parsing to hold statements for which the lexer
cannot yet determine what class it should be, usually because there are
insufficient clues, or it might be more than one thing.

You should never encounter these in a fully parsed PDOM tree.

=cut

#####################################################################
package PPI::Statement::Expression;

# A "normal" expression of some sort

BEGIN {
	$PPI::Statement::Expression::VERSION = '0.830';
	@PPI::Statement::Expression::ISA     = 'PPI::Statement';
}





#####################################################################
package PPI::Statement::Break;

# Break out of a flow control block.
# next, last, return.

BEGIN {
	$PPI::Statement::Break::VERSION = '0.830';
	@PPI::Statement::Break::ISA     = 'PPI::Statement';
}





#####################################################################
package PPI::Statement::Null;

# A null statement is a useless statement.
# Usually, just an extra ; on it's own.

BEGIN {
	$PPI::Statement::Null::VERSION = '0.830';
	@PPI::Statement::Null::ISA     = 'PPI::Statement';
}





#####################################################################
package PPI::Statement::Data;

# The section of a file containing data

BEGIN {
	$PPI::Statement::Data::VERSION = '0.830';
	@PPI::Statement::Data::ISA     = 'PPI::Statement';
}





#####################################################################
package PPI::Statement::End;

# The useless stuff (although maybe containing POD) at the end of a file

BEGIN {
	$PPI::Statement::End::VERSION = '0.830';
	@PPI::Statement::End::ISA     = 'PPI::Statement';
}





#####################################################################
package PPI::Statement::UnmatchedBrace;

# An unattached structural clode such as ) ] } found incorrectly at
# the root level of a Document. We create a seperate statement for it
# so that we can continue parsing the code.

BEGIN {
	$PPI::Statement::UnmatchedBrace::VERSION = '0.830';
	@PPI::Statement::UnmatchedBrace::ISA     = 'PPI::Statement';
}





#####################################################################
package PPI::Statement::Unknown;

# We are unable to definitely catagorize the statement from the first
# token alone. Do additional checks when adding subsequent tokens.

# Currently, the only time this happens is when we start with a label

BEGIN {
	$PPI::Statement::Unknown::VERSION = '0.830';
	@PPI::Statement::Unknown::ISA     = 'PPI::Statement';
}

1;

=pod

=head1 TO DO

- Complete, freeze and document the remaining classes

- Complete support for lexing of labels for all statement types

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main PPI Manual

=head1 AUTHOR

Adam Kennedy (Maintainer), L<http://ali.as/>, cpan@ali.as

Thank you to Phase N (L<http://phase-n.com/>) for permitting
the open sourcing and release of this distribution.

=head1 COPYRIGHT

Copyright (c) 2004 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
