#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;
use Test::XML;
use IPC::Run qw(run);
use File::Slurp qw(slurp);

###############################################################################
# TEST: Run "tap2junit" in filter mode (in STDIN, out STDOUT)
tap2junit_filter: {
    my $tap = slurp('t/data/tap/simple');
    my $xml = slurp('t/data/tap/junit/simple');

    my @cmd = ($^X, '-Ilib', 'script/tap2junit', '--name' => 'data_tap_simple', '-');
    my ($out, $err);
    run \@cmd, \$tap, \$out, \$err or die $?;

    # The "timestamp" attribute records the wall-clock start of the suite and is
    # therefore non-deterministic; strip it before comparing against the static
    # fixture.  Its presence and format are exercised separately in timer.t.
    $out =~ s/\s+timestamp="[^"]*"//g;

    is_xml $out, $xml, 'results generated on STDOUT';
}
