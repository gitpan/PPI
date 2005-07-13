package PPI::Normal;

=pod

=head1 NAME

PPI::Normal - Normalize Perl Documents

=head2 DESCRIPTION

Perl Documents, as created by PPI, are typically filled with all sorts of
mess such as whitespace and comments and other things that don't effect
the actual meaning of the code.

In addition, because there is more than one way to do most things, and the
syntax of Perl itself is quite flexible, there are many ways in which the
"same" code can look quite different.

PPI::Normal attempts to resolve this by providing a variety of mechanisms
and algorithms to "normalize" Perl Documents, and determine a sort of base
form for them (although this base form will be a memory structure, and
not something that can be turned back into Perl source code).

The process itself is quite complex, and so for convenience and
extensibility it has been separated into a number of layers. At a later
point, it will be possible to write Plugin classes to insert additional
normalization steps into the various different layers.

In addition, you can choose to do the normalization only as deep as a
particular layer, depending on aggressively you want the normalization
process to be.

=head1 METHODS

=cut

use strict;
use UNIVERSAL 'isa';
use List::MoreUtils ();
use PPI::Document::Normalized ();

use vars qw{$VERSION $errstr %LAYER};
BEGIN {
	$VERSION = '1.002';
	$errstr  = '';

	# Registered function store
	%LAYER = (
		1 => [],
		2 => [],
		);
}





#####################################################################
# Configuration

=pod

=head2 register $function => $layer, ...

The C<register> method is used by normalization method providers to
tell the normalization engines which functions need to be run, and
in which layer they apply.

Provide a set of key/value pairs, where the key is the full name of the
function (in string form), and the value is the layer (see description
of the layers above) in which it should be run.

Returns true if all functions are registered, or C<undef> on error.

=cut

sub register {
	my $class = shift;
	while ( @_ ) {
		# Check the function
		my $function = shift;
		{ no strict 'refs';
			defined $function and defined &{"$function"} or return undef;
		}

		# Has it already been added?
		if ( List::MoreUtils::any { $_ eq $function } ) {
			return 1;
		}

		# Check the layer to add it to
		my $layer = shift;
		defined $layer and $layer =~ /^(?:1|2)$/ or return undef;

		# Add to the layer data store
		push @{ $LAYER{$layer} }, $function;
	}

	1;
}

# With the registration mechanism in place, load in the main set of
# normalization methods to initialize the store.
use PPI::Normal::Standard;





#####################################################################
# Constructor and Accessors

=pod

=head2 new

Creates a new normalization level 1 object, to which Document objects
can be passed to be normalized.

Of course, what you probably REALLY want is just to call
L<PPI::Document>'s C<normalize> method.

Returns a new PPI::Normal object, or C<undef> on error.

B<Note>

Unless it can be shown there's a string reason to make this instantiable,
this may degrade into a non-instantiable class at a later date (although
the PPI::Document C<normalize> will stay as is).

=cut

sub new {
	my $class = shift->_clear;

	# Create the object
	my $object = bless {
		layer => 2,
		}, $class;

	$object;
}

sub layer { $_[0]->{layer} }





#####################################################################
# Main Methods

sub process {
	my $self     = ref $_[0] ? shift->_clear : shift->new;
	my $Document = isa(ref $_[0], 'PPI::Document') ? shift : return undef;

	# Fail if object is already in use
	return undef if $self->{Document};

	# Set up for processing run
	$self->{Document} = $Document;

	# Work out what functions we need to call
	my @functions = ();
	foreach ( 1 .. $self->layer ) {
		push @functions, @{ $LAYER{$_} };
	}

	# Execute each function
	foreach my $function ( @functions ) {
		no strict 'refs';
		&{"$function"}( $Document );
	}

	# Create the normalized Document object
	my $Normalized = PPI::Document::Normalized->new(
		Document  => $Document,
		version   => $VERSION,
		functions => \@functions,
		) or return undef;

	$Normalized;
}





#####################################################################
# Error Handling

sub errstr { $errstr }
sub _error { $errstr = $_[1]; undef }
sub _clear { $errstr = ''; $_[0] }

1;

=pod

=head1 NOTES

The following normalisation layers are implemented. When writing
plugins, you should register each transformation function with the
appropriate layer.

=head2 Layer 1 - Insignificant Data Removal

The basic step common to all normalization, layer 1 scans through the
Document and removes all whitespace, comments, POD, and anything else
that returns false for its C<significant> method.

It also checks each Element and removes known-useless sub-element
metadata such as the Element's physical position in the file.

=head2 Layer 2 - Significant Element Removal

After the removal of the insignificant data, Layer 2 removed larger, more
complex, and superficially "significant" elements, that can be removed
for the purposes of normalisation.

Examples from this layer include pragmas, now-useless statement
separators (since the PDOM tree is holding statement elements), and
several other minor bits and pieces.

=head2 Layer 3 - TO BE COMPLETED

This version of the forward-port of the Perl::Compare functionality
to the 0.900+ API of PPI only implements Layer 1 and 2 at this time.

=head1 TO DO

- Write the other 4-5 layers :)

=head1 SUPPORT

See the L<support section|PPI/SUPPORT> in the main module

=head1 AUTHOR

Adam Kennedy, L<http://ali.as/>, cpan@ali.as

=head1 COPYRIGHT

Copyright (c) 2005 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
