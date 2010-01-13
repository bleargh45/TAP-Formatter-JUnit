#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;
use Test::Differences;
use IPC::Open2 qw(open2);
use File::Slurp qw(slurp);

###############################################################################
# TEST: Run "tap2junit" in filter mode (in STDIN, out STDOUT)
tap2junit_filter: {
    my $tap = slurp('t/data/tap/simple');
    my $xml = slurp('t/data/tap/junit/simple');

    my ($chld_in, $chld_out);
    my $pid = open2($chld_out, $chld_in,
        qq($^X -Iblib/lib blib/script/tap2junit --name data_tap_simple -)
    );
    ok $pid, 'tap2junit started';

    print $chld_in $tap;
    close $chld_in;

    my $received = do { local $/; <$chld_out> };
    eq_or_diff $received, $xml, 'results generated on STDOUT';
}
