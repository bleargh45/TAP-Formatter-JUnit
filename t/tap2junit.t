#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Differences;
use File::Slurp qw(slurp);

###############################################################################
# Figure out how many TAP files we have to run.  Yes, the results *ARE* going
# to be different when parsing the raw TAP output than when running under
# 'prove'; we won't have any context of "did the test die a horrible death?"
my @tests = grep { -f $_ } <t/data/tap/*>;
plan tests => scalar(@tests);

###############################################################################
# Run each of the TAP files in turn through 'tap2junit', and compare the output
# to the expected JUnit output in each case.
foreach my $test (@tests) {
    (my $junit = $test) =~ s{/tap/}{/tap/junit/};

    my $rc = system(qq{ $^X -Ilib bin/tap2junit $test 2>/dev/null });

    my $outfile  = "$test.xml";
    my $received = slurp($outfile);
    unlink $outfile;

    my $expected = slurp($junit);

    eq_or_diff $received, $expected, $test;
}
