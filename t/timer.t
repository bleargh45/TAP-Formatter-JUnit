#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 20;
use TAP::Harness;
use IO::Scalar;
use File::Slurp qw(write_file);

###############################################################################
# When timer is disabled, we should have *NO* timer info in the JUnit output.
timer_disabled: {
    my $test     = qq|
        use Test::More tests => 1;
        pass 'no timing in this test';
    |;
    my $results = run_test($test, {
        timer => 0,
    } );
    ok $results, 'got JUnit';
    unlike $results, qr/time/ism, '... without any timing information';
}

###############################################################################
# When timer is enabled, JUnit output *should* have timer info in it.
timer_enabled: {
    my $test     = qq|
        use Test::More tests => 2;
        pass 'one';
        pass 'two';
    |;
    my $results = run_test($test, {
        timer => 1,
    } );
    ok $results, 'got JUnit';
    like $results, qr/time/ism, '... with timing information';
}

###############################################################################
# Ensure timing correctness, when test has a plan
#
# Test once with merged output off, then once with it on; want to make sure that
# merging diagnostic output into the TAP doesn't monkey up the timings.
correct_timing_test_has_plan: {
    my $test     = qq|
        use Test::More tests => 3;
        BEGIN { sleep 3 };
        END   { sleep 2 };
        sleep 0;    pass "one";
        sleep 2;    pass "two";

        sleep 1;    diag "foo";
        sleep 1;    diag "bar";
        sleep 3;    diag "foobar";
        pass "three";
    |;
    my $expect = {
        '(init)'     => 3,
        '1 - one'    => 0,
        '2 - two'    => 2,
        '3 - three'  => 5,
        '(teardown)' => 2,
    };

    unmerged: {
        my $results = run_test($test, {
            timer => 1,
            merge => 0,
        } );
        ok $results, 'got JUnit - timing correctness w/test plan (unmerged)';
        verify_timings($results, $expect);
    }

    merged: {
        my $results = run_test($test, {
            timer => 1,
            merge => 1,
        } );
        ok $results, 'got JUnit - timing correctness w/test plan (merged)';
        verify_timings($results, $expect);
    }
}

###############################################################################
# Ensure timing correctness, when test has no plan
#
# The *first* test isn't going to be predictable/accurate w.r.t. the calculated
# timing, as it'll also involve the startup overhead.  As such, its skipped (by
# denoting it as "skip" in its test name).
correct_timing_test_unplanned: {
    my $test     = qq|
        use Test::More qw(no_plan);
        BEGIN { sleep 3 };
        END   { sleep 2 };
        sleep 0;    pass "one";
        sleep 2;    pass "two";

        sleep 1;    diag "foo";
        sleep 1;    diag "bar";
        sleep 3;    diag "foobar";
        pass "three";
    |;
    my $expect = {
        '1 - one'    => 3,  # init time is *hidden* in initial test
        '2 - two'    => 2,
        '3 - three'  => 5,
        '(teardown)' => 2,
    };

    my $results = run_test($test, {
        timer => 1,
        merge => 1,
    } );
    ok $results, 'got JUnit - timing correctness w/o test plan';
    verify_timings($results, $expect);
}

sub run_test {
    my $code = shift;
    my $opts = shift;
    my $file = "test-$$.t";

    my $junit = undef;
    my $fh    = IO::Scalar->new(\$junit);
    my $harness = TAP::Harness->new( {
        formatter_class => 'TAP::Formatter::JUnit',
        stdout          => $fh,
        %{$opts},
    } );

    write_file($file, $code);
    $harness->runtests($file);
    unlink $file;

    return $junit;
}

sub verify_timings {
    my $junit  = shift;
    my $expect = shift;

    my @lines = split /^/, $junit;
    my @tests = grep { /<testcase/ } @lines;

    foreach my $test (@tests) {
        my ($time, $name) = ($test =~ /time="([^"]+)" name="([^"]+)"/);
        if (!defined $time) {
            fail "... unexpected test line: $test";
            next;
        }

        if (exists $expect->{$name}) {
            rounds_to($time, $expect->{$name}, "... test timing: $name");
        }
        else {
            fail "... unexpected test name: $name";
            diag $test;
        }
    }
}

sub rounds_to {
    my ($got, $expected, $message) = @_;
    my $r_got      = sprintf('%1.0f', $got);
    my $r_expected = sprintf('%1.0f', $expected);
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is $r_got, $r_expected, $message;
}
