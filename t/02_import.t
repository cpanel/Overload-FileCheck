#!/usr/bin/perl -w

use strict;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck '-e' => \&my_dash_e;

my @exist     = qw{cherry banana apple};
my @not_there = qw{mum and dad};

sub my_dash_e {
    my $f = shift;

    note "mocked -e called for", $f;

    return 1 if grep { $_ eq $f } @exist;
    return 0 if grep { $_ eq $f } @not_there;

    # we have no idea about these files
    return -1;
}

foreach my $f (@exist) {
    ok( -e $f, "file '$f' exists" );
}

foreach my $f (@not_there) {
    ok( !-e $f, "file '$f' exists" );
}

ok -e $0,  q[$0 is there];
ok -e $^X, q[$^X is there];

done_testing;
