#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;
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
