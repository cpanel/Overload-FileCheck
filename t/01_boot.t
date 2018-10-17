#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck ();

is Overload::FileCheck::_loaded(), 1, '_loaded';

my @ops = qw{ OP_FTIS OP_FTFILE };    # TODO move them to the xs code ?
foreach my $op (@ops) {
    my $op_type = Overload::FileCheck->can($op)->();
    ok( $op_type, "$op_type: $op" );
}

is Overload::FileCheck::CHECK_IS_TRUE(),       1,  "CHECK_IS_TRUE";
is Overload::FileCheck::CHECK_IS_FALSE(),      0,  "CHECK_IS_FALSE";
is Overload::FileCheck::FALLBACK_TO_REAL_OP(), -1, "FALLBACK_TO_REAL_OP";

is Overload::FileCheck::ST_DEV(), 0, "ST_DEV";
is Overload::FileCheck::ST_INO(), 1, "ST_INO";

# ...
is Overload::FileCheck::ST_BLOCKS(),  12, "ST_BLOCKS";
is Overload::FileCheck::STAT_T_MAX(), 13, "STAT_T_MAX";

done_testing;
