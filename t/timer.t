#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 14;
use TAP::Harness;
use IO::Scalar;

###############################################################################
# When timer is disabled, we should have *NO* timer info in the JUnit output.
timer_disabled: {
    my $results = undef;
    my $fh      = IO::Scalar->new(\$results);
    my $harness = TAP::Harness->new( {
        formatter_class => 'TAP::Formatter::JUnit',
        timer           => 0,
        stdout          => $fh,
    } );

    $harness->runtests('t/data/tests/simple');
    ok $results, 'got JUnit';
    unlike $results, qr/time/ism, '... without any timing information';
}

###############################################################################
# When timer is enabled, JUnit output *should* have timer info in it.
timer_enabled: {
    my $results = undef;
    my $fh      = IO::Scalar->new(\$results);
    my $harness = TAP::Harness->new( {
        formatter_class => 'TAP::Formatter::JUnit',
        timer           => 1,
        stdout          => $fh,
    } );

    $harness->runtests('t/data/tests/simple');
    ok $results, 'got JUnit';
    like $results, qr/time/ism, '... with timing information';
}

###############################################################################
# Ensure timing correctness, when test has a plan
#
# Test once with merged output off, then once with it on; want to make sure that
# merging diagnostic output into the TAP doesn't monkey up the timings.
correct_timing_test_has_plan: {
    unmerged: {
        my $results = undef;
        my $fh      = IO::Scalar->new(\$results);
        my $harness = TAP::Harness->new( {
            formatter_class => 'TAP::Formatter::JUnit',
            timer           => 1,
            stdout          => $fh,
        } );

        $harness->runtests('t/data/timer/planned');
        ok $results, 'got JUnit - timing correctness w/test plan (unmerged)';
        verify_timing_correctness($results);
    }

    merged: {
        my $results = undef;
        my $fh      = IO::Scalar->new(\$results);
        my $harness = TAP::Harness->new( {
            formatter_class => 'TAP::Formatter::JUnit',
            timer           => 1,
            merge           => 1,
            stdout          => $fh,
        } );

        $harness->runtests('t/data/timer/planned');
        ok $results, 'got JUnit - timing correctness w/test plan (merged)';
        verify_timing_correctness($results);
    }
}

###############################################################################
# Ensure timing correctness, when test has no plan
#
# The *first* test isn't going to be predictable/accurate w.r.t. the calculated
# timing, as it'll also involve the startup overhead.  As such, its skipped (by
# denoting it as "skip" in its test name).
correct_timing_test_unplanned: {
    my $results = undef;
    my $fh      = IO::Scalar->new(\$results);
    my $harness = TAP::Harness->new( {
        formatter_class => 'TAP::Formatter::JUnit',
        timer           => 1,
        merge           => 1,
        stdout          => $fh,
    } );

    $harness->runtests('t/data/timer/no-plan');
    ok $results, 'got JUnit - timing correctness w/o test plan';
    verify_timing_correctness($results);
}

sub verify_timing_correctness {
    my $junit = shift;
    my @lines = split /^/, $junit;
    my @tests = grep { /<testcase/ } @lines;

    foreach my $test (@tests) {
        my ($time, $name) = ($test =~ /time="([^"]+)" name="\d+\s+-\s+([^"]+)"/);
        if (!defined $time) {
            ok 0, "... unexpected test line: $test";
            next;
        }

        # there are known times when the test time is unpredictable, but they're
        # noted as "skip".
        next if ($name =~ /skip/);

        # see how long test was _supposed_ to have taken, and see if we're
        # close.
        if ($name =~ /slept (\d+) seconds/) {
            my $expected = $1;
            is int($time), int($expected), "... test timing: $name";
        }
        else {
            ok 0, "... unexpected test name: $name";
        }
    }
}
