package PPI::Util;

# Provides some common utility functions that can be imported

use strict;
use base 'Exporter';
use Digest::MD5   ();
use PPI::Document ();
use Params::Util '_INSTANCE',
                 '_SCALAR';

use vars qw{$VERSION @EXPORT_OK};
BEGIN {
	$VERSION   = '1.101';
	@EXPORT_OK = qw{_Document _slurp};
}





#####################################################################
# Functions

# Allows a sub that takes a L<PPI::Document> to handle the full range
# of different things, including file names, SCALAR source, etc.
sub _Document {
	shift if @_ > 1;
	return undef unless defined $_[0];
	return PPI::Document->new( shift ) unless ref $_[0];
	return PPI::Document->new( shift ) if _SCALAR($_[0]);
	return shift if _INSTANCE($_[0], 'PPI::Document');
	undef;
}

# Provide a single _slurp implementation
sub _slurp {
	my $file = shift;
	local $/ = undef;
	open( PPIUTIL, '<', $file ) or return "open($file) failed: $!";
	my $source = <PPIUTIL>;
	close( PPIUTIL ) or return "close($file) failed: $!";
	\$source;
}

# Provides a version of Digest::MD5's md5hex that explicitly
# works on the unix-newlined version of the content.
sub md5hex {
	my $string = shift;
	$string =~ s/(?:\015{1,2}\012|\015|\012)/\015/s;
	Digest::MD5::md5_hex($string);
}

1;
