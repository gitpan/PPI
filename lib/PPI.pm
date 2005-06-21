package PPI;

# See POD at end for documentation

use 5.005;
use strict;
# use warnings;
# use diagnostics;
use UNIVERSAL 'isa';
use Class::Inspector ();
use Class::Autouse   ();

# Set the version for CPAN
use vars qw{$VERSION $XS_COMPATIBLE @XS_EXCLUDE};
BEGIN {
	$VERSION       = '0.993';
	$XS_COMPATIBLE = '0.845';
	@XS_EXCLUDE    = ();
}

# Always load the entire PDOM
use PPI::Element   ();
use PPI::Token     ();
use PPI::Statement ();
use PPI::Structure ();

# Autoload the remainder of the classes
use Class::Autouse 'PPI::Document',
                   'PPI::Document::Normalized',
                   'PPI::Normal',
                   'PPI::Tokenizer',
                   'PPI::Lexer';

# If it is installed, load in PPI::XS
if ( Class::Inspector->installed('PPI::XS') ) {
	require PPI::XS unless $PPI::XS_DISABLE;
}

1;

__END__

=pod

=head1 NAME

PPI - Parse, Analyze and Manipulate Perl (without perl) - BETA 2

=head1 SYNOPSIS

  use PPI;
  
  # Create a new empty document
  my $Document = PPI::Document->new;
  
  # Create a document from source
  $Document = PPI::Document->new('print "Hello World!\n"');
  
  # Load a Document from a file
  $Document = PPI::Document->load('Module.pm');
  
  # Does it contain any POD?
  if ( $Document->find_any('PPI::Token::Pod') ) {
      print "Module contains POD\n";
  }
  
  # Get the name of the main package
  $pkg = $Document->find_first('PPI::Statement::Package')->namespace;
  
  # Remove all that nasty documentation
  $Document->prune('PPI::Token::Pod');
  $Document->prune('PPI::Token::Comment');
  
  # Save the file
  $Document->save('Module.pm.stripped');

=head1 STATUS

As of version 0.900, PPI is officially feature-frozen and in beta.

The core PPI feature-set is now implemented, and the API now supports all
of the major language structures, and should be able to handle the entire
perl syntax.

Source filters are not and will not (and can not) be supported.

The class structure of the PDOM (Perl Document Object Model) is complete
and frozen. All of the analysis methods within the PDOM that are documented
can also be considered frozen.

Most of the non-core distributions have also been brought up to date.

The following packages are all also considered up to date.

=head1 DESCRIPTION

=head2 About this Document

This is the PPI manual. It describes PPI, its reason for existing, its
structure, its use, an overview of the API, and provides implementation
samples.

=head2 Background

The ability to read, and manipulate perl (programmatically) other than with
the perl executable is one that has caused difficulty for a long time.

The root cause of this problem is perl's dynamic grammar. Although there
are typically not huge differences in the grammar of most code, some things
cause large problems.

An example of these are function signatures, as demonstrated by the following.

  @result = (dothis $foo, $bar);
  
  # Which of the following is it equivalent to?
  @result = (dothis($foo), $bar);
  @result = dothis($foo, $bar);

This code can be interpreted in two different ways, depending on whether the
C<&dothis> function is expecting one argument, or two, or several.

To restate, a true or "real" parser needs information that can not be found
in the immediate vicinity. In fact, this information might not even be in the
same file. It might also not be able to determine this without the prior
execution of a C<BEGIN {}> block. In other words, to parse perl, you must
also execute it, or if not it, everything that it depends on for its grammar.

This, while possibly feasible in some circumstances, is not a valid solution
( at least, so far as this module is concerned ). Imagine trying to parse some
code that had a dependency on the C<Win32::*> modules from a Unix machine, or
trying to parse some code with a dependency on another module that had not
even been written yet...

For more information on why it is impossible to parse perl, see:

L<http://www.perlmonks.org/index.pl?node_id=44722>

=head2 Why "Isolated"?

Originally, PPI was short for Parse::Perl::Isolated. In aknowledgement that
someone may some day come up with a valid solution for the grammar problem,
it was decided to leave the C<Parse::Perl> namespace free.

The purpose of this parser is not to parse Perl B<code>, but to parse Perl
B<documents>. In most cases, a single file is valid as both. By treating the
problem this way, we can parse a single file containing Perl source isolated
from any other resources, such as the libraries upon which the code may depend,
and without needing to run an instance of perl alongside or inside the the
parser (a possible solution for Parse::Perl that is investigated from time to
time).

=head2 Why do we want to parse?

Once we accept that we will probably never be able to parse perl well enough
to execute it, it is worth re-examining C<WHY> we wanted to "parse" perl in
the first place. What are the uses we would put such a parser to.

=over 4

=item Documentation

Analyze the contents of a Perl document to automatically generate
documentation, in parallel to, or as a replacement for, POD documentation.

=item Structural and Quality Analysis

Determine quality or other metrics across a body of code, and identify
situations relating to particular phrases, techniques or locations.

=item Refactoring

Make structural, syntax, or other changes to code in an automated manner,
independently, or in assistance to an editor. This list includes backporting,
forward porting, partial evaluation, "improving" code, or whatever.

=item Layout

Change the layout of code without changing its meaning. This includes
techniques such as tidying (like perltidy), obfuscation, compression, or to
implement formatting preferences or policies.

=item Presentation

This includes method of improving the presentation of code, without changing
the text of the code. Modify, improve, syntax colour etc the presentation of
a Perl document.

=back

With these goals identified, as long as the above tasks can be achieved,
with some sort of reasonable guarantee that the code will not be damaged in
the process, then PPI can be considered to be a success.

=head2 Good Enough(TM)

With the above tasks in mind, PPI seeks to be good enough to achieve the
above tasks, or to provide a sufficiently good API on which to allow others
to implement modules in these and related areas.

However, there are going to be limits to this process. Because PPI cannot
adapt to changing grammars, any code written using code filters should not
be assumed to be parsable. At one extreme, this includes anything munged by
L<Acme::Bleach|Acme::Bleach>, as well as (arguably) more common cases like
L<Switch.pm|Switch> and L<Exception.pm|Exception>. We do not pretend to be
able to parse code using these modules, although someone may be able to
extend PPI to handle them.

UPDATE: The ability to extend PPI to handle lexical additions to the
language, which means handling filters that LOOK like they should be perl,
but aren't, is on the drawing board to be done some time post-1.0

The goal for success is thus to be able to successfully parse 99% of all
Perl documents contained in CPAN. This means the entire file in each case.

=head1 IMPLEMENTATION

=head2 General Layout

PPI is built upon two primary "parsing" components, L<PPI::Tokenizer>
and L<PPI::Lexer>, and a large tree of nearly 50 classes which implement
the various objects within the Perl Document Object Model (PDOM).

The Perl Document Object Model is somewhat similar in style and intent to the
regular DOM, but contains many differences to handle perl-specific cases.

On top of the Tokenizer and Lexer, and the classes of the PDOM, sit a number
of classes intended to make life a little easier when dealing with PDOM
object trees.

Both the major parsing components were implemented from scratch with just
plain Perl code. There are no grammar rules, no YACC or LEX style tools, just
code. This is primarily because of the sheer volume of accumulated cruft that
exists in perl. Not even perl itself is capable of parsing perl documents
(remember, it just parses and executes it as code) so PPI needs to be even
cruftier than perl itself. Yes, eewww...

=head2 The Tokenizer

The Tokenizer is considered complete and of release candidate quality.
Not quite fully "stable", but close.

The Tokenizer takes source code and converts it into a series of tokens. It
does this using a slow but thorough character by character manual process,
rather than using complex regexs. Well, that's actually a lie, it has a lot
of support regexs throughout, and it's not truly character by character. The
Tokenizer is increasingly "skipping ahead" when it can find shortcuts, so
the "current character" cursor tends to jump a bit wildly. Remember that
cruft I was mentioning. Right, well the tokenizer is full of it. In reality,
the number of times the Tokenizer will ACTUALLY move the character cursor
itself is only about 5% - 10% higher than the number of tokens in the file.

Currently, these speed issues mean that PPI is not of great use for highly
interactive tasks, such as an editor which checks and formats code on
the fly. This situation is improving somewhat with multi-gigahertz
processors, but can still be painful at times.

How slow? As an example, tokenizing CPAN.pm, a 7112 line, 40,000 token file
takes about 5 seconds on my little Duron 800 test server. So you should
expect the tokenizer to work at a rate of about 1700 lines of code per
gigacycle. The code gets tweaked and improved all the time, and there is a
fair amount of scope left for speed improvements, but it is painstaking work,
and fairly slow going.

The target rate is about 5000 lines per gigacycle.

The main avenue for making it to this speed has now become L<PPI::XS>, a
drop-in XS accelerator for miscellaneous parts of PPI.

Since L<PPI::XS> has only just gotten off the ground and is currently only
at proof-of-concept stage, this may take a little while.

=head2 The Lexer

The Lexer is considered complete, but subject to minor. Early beta quality.

The Lexer takes a token stream, and converts it to a lexical tree. Again,
remember we are parsing Perl B<documents> here, not code, so this includes
whitespace, comments, and all number of weird things that have no relevance
when code is actually executed.

An instantiated L<PPI::Lexer> object consumes L<PPI::Tokenizer> objects, or
things that can be converted into one, and produces L<PPI::Document> objects.

=head1 Overview of the Perl Document Object Model

The PDOM is a structured collection of data classes that together provide
a correct and scalable model for documents that follow the standard Perl
syntax.

Although this is a basic overview and doesn't cover the PDOM classes in
order or details, the following is a rough inheritance layout of the
main core classes.

  PPI::Element
    PPI::Token
      PPI::Token::*
    PPI::Node
      PPI::Statement
        PPI::Statement::*
      PPI::Structure
        PPI::Structure::*
      PPI::Document

To summarize the above layout, all PDOM objects inherit from the
L<PPI::Element> class.

Under this are L<PPI::Token>, strings of content with a known type,
and L<PPI::Node>, contains to hold other Elements.

The first PDOM element you are likely to encounter is the B<PPI::Document>
object.

=head2 The Document

At the top of all complete PDOM trees is a L<PPI::Document> object. Each
Document will contain a number of B<Statements>, B<Structures> and
B<Tokens>.

A L<PPI::Statement> is any series of Tokens and Structures that are treated
as a single contiguous statement by perl itself. You should note that a
Statement is as close as PPI can get to "parsing" the code in the sense that
perl-itself parses Perl code when it is building the op-tree. PPI cannot tell
you, for example, which tokens are subroutine names, or arguments to a sub
call, or what have you.

At a fundamental level, it only knows that this series of elements represents
a single Statement. For specific Statement types however, the PDOM is able
to derive additional useful information.

A L<PPI::Structure> is any series of tokens contained within matching braces.
This includes things like code blocks, conditions, function argument braces,
anonymous array constructors, lists, scoping braces et al. Each Structure
contains none, one, or many Tokens and Structures (the rules for which vary
for the different Structure subclasses)

=head2 The PDOM at Work

To demonstrate, lets start with an example showing how the PDOM tree might look
for the following chunk of simple Perl code.

  #!/usr/bin/perl

  print( "Hello World!" );

  exit();

This is not all that complicated. Very very simple in fact. Translated into
a PDOM tree it would have the following structure.

  PPI::Document
    PPI::Token::Comment                '#!/usr/bin/perl\n'
    PPI::Token::Whitespace             '\n'
    PPI::Statement
      PPI::Token::Bareword             'print'
      PPI::Structure::List             ( ... )
        PPI::Token::Whitespace         ' '
        PPI::Statement::Expression
          PPI::Token::Quote::Double    '"Hello World!"'
        PPI::Token::Whitespace         ' '
      PPI::Token::Structure            ';'
    PPI::Token::Whitespace             '\n'
    PPI::Token::Whitespace             '\n'
    PPI::Statement
      PPI::Token::Bareword             'exit'
      PPI::Structure::List             ( ... )
      PPI::Token::Structure            ';'
    PPI::Token::Whitespace             '\n'

Please note that in this this example, strings are only listed for the ACTUAL
element that contains the string. Also, Structures are listed with the brace
characters noted.

The L<PPI::Dumper> module can be used to generate similar trees yourself.

Notice how PPI builds EVERYTHING into the model, including whitespace. This
is needed in order to make the Document fully "round trip" compliant. That
is, if you stringify the Document you get the same file you started with.

The one exception is that if the newlines for your file are wrong, PPI
will probably have localised them for you.

We can make that PDOM dump a little easier to read if we strip out all the
whitespace. Here it is again, sans the distracting whitespace tokens.

  PPI::Document
    PPI::Token::Comment                '#!/usr/bin/perl\n'
    PPI::Statement
      PPI::Token::Bareword             'print'
      PPI::Structure::List             ( ... )
        PPI::Statement::Expression
          PPI::Token::Quote::Double    '"Hello World!"'
      PPI::Token::Structure            ';'
    PPI::Statement
      PPI::Token::Bareword             'exit'
      PPI::Structure::List             ( ... )
      PPI::Token::Structure            ';'

As you can see, the tree can get fairly deep at time, especially when every
isolated token in a bracket becomes its own statement. This is needed to
allow anything inside the tree the ability to grow. It also makes the
search and analysis algorithms much more flexible.

Because of the depth and complexity of PDOM trees, a vast number of very easy
to use methods have been added wherever possible to help people working with
PDOM trees do normal tasks relatively quickly and efficiently.

=head1 CLASSES

This section has two parts.

Firstly a large tree of all the classes contained in the PPI core. They are
listed only by name, with no description.

And second, a shorter list with descriptions for the primary classes in the
core PPI distribution. The list is in alphabetical order. Anything with its
own POD documentation can be considered stable, as the POD is only written
after the API is largely finalised and frozen. Still, don't rely on anything
here until after PPI official becomes a beta, in the 0.9xx versions.

=head2 Perl Document Object Model Classes

   PPI::Element
      PPI::Node
         PPI::Document
            PPI::Document::Fragment
         PPI::Statement
            PPI::Statement::Scheduled
            PPI::Statement::Package
            PPI::Statement::Include
            PPI::Statement::Sub
            PPI::Statement::Variable
            PPI::Statement::Compound
            PPI::Statement::Break
            PPI::Statement::Data
            PPI::Statement::End
            PPI::Statement::Expression
            PPI::Statement::Null
            PPI::Statement::UnmatchedBrace
            PPI::Statement::Unknown
         PPI::Structure
            PPI::Structure::Block
            PPI::Structure::Subscript
            PPI::Structure::Constructor
            PPI::Structure::Condition
            PPI::Structure::List
            PPI::Structure::ForLoop
            PPI::Structure::Unknown
      PPI::Token
         PPI::Token::Whitespace
         PPI::Token::Comment
         PPI::Token::Pod
         PPI::Token::Number
         PPI::Token::Word
         PPI::Token::DashedWord
         PPI::Token::Symbol
            PPI::Token::Magic
         PPI::Token::ArrayIndex
         PPI::Token::Operator
         PPI::Token::Quote
            PPI::Token::Quote::Single
            PPI::Token::Quote::Double
            PPI::Token::Quote::Literal
            PPI::Token::Quote::Interpolate
         PPI::Token::QuoteLike
            PPI::Token::QuoteLike::Backtick
            PPI::Token::QuoteLike::Command
            PPI::Token::QuoteLike::Regexp
            PPI::Token::QuoteLike::Words
            PPI::Token::QuoteLike::Readline
         PPI::Token::Regexp
            PPI::Token::Regexp::Match
            PPI::Token::Regexp::Substitute
            PPI::Token::Regexp::Transliterate
         PPI::Token::HereDoc
         PPI::Token::Cast
         PPI::Token::Structure
         PPI::Token::Label
         PPI::Token::Separator
         PPI::Token::Data
         PPI::Token::End
         PPI::Token::Prototype
         PPI::Token::Attribute
         PPI::Token::Unknown

=head2 Class Summary

=over 4

=item L<PPI::Tokenizer>

The PPI Tokenizer consumes chunks of text and provides access to a stream
of PPI::Token objects. The Tokenizer is really nastily complicated, to the
point where even the author treads a bit carefully when working with it.

Most of the complication is the result of optimizations which have tripled
the tokenization speed, at the expense of maintainability. Yeah, I know...

Because the Tokenizer holds the array of Tokens internally, providing
cursor-based access to it, an instantiate Tokenizer object can only be used
B<once>, unlike the Lexer which just spits out a single L<PPI::Document>
object and can be reused as needed.

=item L<PPI::Lexer>

The PPI Lexer. Converts Token streams into PDOM trees.

=item L<PPI::Dumper>

A simple class for dumping readable debugging version of PDOM structures

=item PPI::Token::_QuoteEngine

The L<PPI::Token::Quote> and L<PPI::Token::QuoteLike> classes provide
abstract base classes for the many and varied types of quote and quote-like
things in perl. However, much of the actual quote login is implemented in
a separate quote engine, based at L<PPI::Token::_QuoteEngine>.

Classes that inherit from PPI::Token::Quote, PPI::Token::QuoteLike and the
base Regexp class L<PPI::Token::Regexp> are generally parsed only by the
Quote Engine.

=item L<PPI::Document>

The Document object, the top of the PDOM

=item L<PPI::Document::Fragment>

A cohesive fragment of a larger Document. Currently Incomplete.

Will be used later on for cut/paste/insert etc. Very similar to
PPI::Document, but has some additional methods, and does not represent a
lexical scope boundary.

=item L<PPI::Element>

The Element class is the abstract base class for all objects within the PDOM

=item L<PPI::Node>

The Node object, the abstract base class for all PDOM object that can
contain other Elements, such as the Document, Statement and Structure
objects.

=item L<PPI::Statement>

The base class for all Perl statements. Generic "evaluate for side-effects"
statements are of this actual type. Other more interesting statement types
belong to one of its children.

See the L<PPI::Statement> documentation for a longer description
and list of all of the different statement types and subclasses.

=item PPI::Structure

The abstract base class for all structures. A Structure is a language
construct consisting of matching braces containing a set of other elements.

See the PPI::Structure documentation (not yet written) for a description and
list of all of the different structure types/classes.

=item PPI::Token

A token is the basic unit of content. At its most basic, a Token is just
a string tagged with metadata (its class, some additional flags in some
cases).

See the PPI::Token documentation (not yet written) for a description and
list of all of the different Token types/classes

=back

=head1 INSTALLING

The core PPI distribution is pure perl and has been kept as tight as
possible and with as few dependencies as possible.

It should download and install normally on any platform from within
the CPAN and CPANPLUS applications, or directly using the distribution
tarball.

There are no special install instructions for PPI.

=head1 EXTENDING

For the time being, the PPI namespace is to be reserved for the sole
use of the Parse::Perl project and its modules.

L<http://sf.net/parseperl>

You are recommended to use the PPIx:: namespace for PPI-specific
modifications, or Perl:: for modules which provide a general Perl
language-related functions.

=head1 TO DO

- Complete documentation for the remaining PPI classes

- More analysis methods for PDOM classes

- Creation of a PPI tutorial

- Expansion of the unit test suite

- More documentation

=head1 SUPPORT

Anything documented is considered to be loosely frozen, and bugs should
always be reported at:

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PPI>

For other issues, or commercial enhancement or support, contact the
author.

=head1 AUTHOR

Adam Kennedy, L<http://ali.as/>, cpan@ali.as

=head1 ACKNOWLEDGMENTS

Thank you to Phase N (L<http://phase-n.com/>) for permitting
the original open sourcing and release of this distribution.

Completion funding provided by The Perl Foundation
(L<http://www.perlfoundation.org/>)

=head1 COPYRIGHT

Copyright (c) 2004 - 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
