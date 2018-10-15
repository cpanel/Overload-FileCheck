#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck qw{mock_all_file_checks unmock_all_file_checks};

my @exist     = qw{cherry banana apple};
my @not_there = qw{not-there missing-file};

mock_all_file_checks( \&my_custom_check );

sub my_custom_check {
    my ( $check, $f ) = @_;

    if ( $check eq 'e' || $check eq 'f' ) {
        return 1 if grep { $_ eq $f } @exist;
        return 0 if grep { $_ eq $f } @not_there;
    }

    return 0 if $check eq 'd' && grep { $_ eq $f } @exist;

    # fallback to the original Perl OP
    return -1;
}

foreach my $f (@exist) {
    ok( -e $f,  "-e $f is true" );
    ok( -f $f,  "-f $f is true" );
    ok( !-d $f, "-d $f is false" );
}

foreach my $f (@not_there) {
    ok( !-e $f, "-e $f is false" );
    ok( !-f $f, "-f $f is false" );
}

done_testing;
