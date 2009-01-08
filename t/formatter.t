#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Differences;
use File::Slurp qw(slurp);

###############################################################################
# Figure out how many tests we have to run.
#
# *MANY* thanks Andy Armstrong et al. for the fabulous set of tests in
# Test::Harness. :)
my @tests = grep { -f $_ } <t/data/tests/*>;
plan tests => scalar(@tests);

###############################################################################
# Run each of the tests in turn, and compare the output to the expected JUnit
# output.
foreach my $test (@tests) {
    (my $junit = $test) =~ s{/tests/}{/tests/junit/};

    my $received = `$^X -Ilib -S prove --formatter TAP::Formatter::JUnit --merge $test`;
    my $expected = slurp($junit);

    eq_or_diff $received, $expected, $test;
}
