#line 1 "inc/Test/SubCalls.pm - /usr/local/share/perl/5.8.4/Test/SubCalls.pm"
package Test::SubCalls;

#line 43

use strict;
use Test::Builder ();
use Hook::LexWrap ();
use base 'Exporter';

use vars qw{$VERSION @EXPORT};
BEGIN {
	$VERSION = '0.01';
	@EXPORT  = qw{sub_track sub_calls sub_reset sub_reset_all};
}

my $Test = Test::Builder->new;

my %CALLS = ();





#####################################################################
# Test::SubCalls Functions

#line 78

sub sub_track {
	# Check the sub name is valid
	my $subname = shift;
	{ no strict 'refs';
		unless ( defined *{"$subname"}{CODE} ) {
			die "Test::SubCalls::sub_track : The sub '$subname' does not exist";
		}
		if ( defined $CALLS{$subname} ) {
			die "Test::SubCalls::sub_track : Cannot add duplicate tracker for '$subname'";
		}
	}

	# Initialise the count
	$CALLS{$subname} = 0;

	# Lexwrap the subroutine
	Hook::LexWrap::wrap( $subname,
		pre => sub { $CALLS{$subname}++ },
		);

	1;
}

#line 120

sub sub_calls {
	# Check the sub name is valid
	my $subname = shift;
	unless ( defined $CALLS{$subname} ) {
		die "Test::SubCalls::sub_calls : Cannot test untracked sub '$subname'";
	}

	# Check the count
	my $count = shift;
	unless ( $count =~ /^(?:0|[1-9]\d*)$/s ) {
		die "Test::SubCalls::sub_calls : Expected count '$count' is not an integer";
	}

	# Get the message, applying default if needed
	my $message = shift
		|| "$subname was called $count times";

	$Test->is_num( $CALLS{$subname}, $count, $message );
}

#line 152

sub sub_reset {
	# Check the sub name is valid
	my $subname = shift;
	unless ( defined $CALLS{$subname} ) {
		die "Test::SubCalls::sub_reset : Cannot reset untracked sub '$subname'";
	}

	$CALLS{$subname} = 0;

	1;
}

#line 175

sub sub_reset_all {
	foreach my $subname ( keys %CALLS ) {
		$CALLS{$subname} = 0;
	}
	1;
}

1;

#line 213