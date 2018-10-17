#!/usr/bin/perl -w

use strict;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck qw(CHECK_IS_FALSE CHECK_IS_TRUE FALLBACK_TO_REAL_OP);

my $call_my_stat = 0;

ok 1, 'start';

my $stat_result = [ stat($0) ];
is scalar @$stat_result, 13, "call stat unmocked";

ok Overload::FileCheck::mock_stat( \&my_stat ), "mock_stat succees";

is $call_my_stat, 0, "my_stat was not called at this point";

$stat_result = [ stat($0) ];
is $call_my_stat, 1, "my_stat is now called" or diag explain $stat_result;

#note explain $stat_result;

my $previous_stat_result = [@$stat_result];

$call_my_stat = 0;
$stat_result  = [ stat(_) ];    # <---- FIXME with the GV check
is $call_my_stat, 0, "my_stat is not called";
is $stat_result, $previous_stat_result, "stat is the same as previously mocked";

$stat_result = [ stat(*_) ];
is $call_my_stat, 0, "my_stat is not called";
is $stat_result, $previous_stat_result, "stat is the same as previously mocked";

note explain $previous_stat_result;

is $previous_stat_result => [
    0,
    0,
    4,
    3,
    2,
    1,
    42,
    10001,
    1000,
    2000,
    3000,
    0,
    0
  ],
  "previous stat result as mocked";

done_testing;

sub my_stat {
    note "=== my_stat from pure perl is called";
    ++$call_my_stat;

    # TODO improve the test to cover all scenario

    #return FALLBACK_TO_REAL_OP;

    return [ 0, 4, 3, 2, 1, 42, 10001, 1000, 2000, 3000, 0, 0 ];

    # the hash alternate
    return { st_dev => 0 };

    #return [ 1..13 ];

    #return q[mummy];
    #return -1;
    return 666;
}
