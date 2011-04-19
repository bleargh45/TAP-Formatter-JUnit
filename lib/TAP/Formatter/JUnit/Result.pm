package TAP::Formatter::JUnit::Result;

use Moose;

has 'time' => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);

has 'result' => (
    is       => 'ro',
    isa      => 'TAP::Parser::Result',
    required => 1,
    handles  => [qw(
        name
        number
        description
        as_string
        raw

        is_test
        is_plan
        is_unplanned
        is_ok

        todo_passed
        explanation
    )],
);

1;
