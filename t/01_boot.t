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

done_testing;
