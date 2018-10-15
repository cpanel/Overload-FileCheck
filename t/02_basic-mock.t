#!/usr/bin/perl -w

use strict;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck;

my @calls;

{
    note "no mocks at this point";

    ok -e q[/tmp], "/tmp/exits";

    ok !-e q[/do/not/exist], "/do/not/exist";

    my $check     = -e q[/do/not/exist];
    my $errno_str = "$!";
    my $errno_int = int($!);

    ok !$check, "file does not exist";
    like $errno_str, qr{No such file or directory}, q[ERRNO set to "No such file or directory"];
    is $errno_int, 2, "ERRNO int value set";

    is \@calls, [], 'no calls';
}

{
    note "we are mocking -e => 1";
    Overload::FileCheck::mock_file_check(
        '-e' => sub {
            my $f = shift;

            note "mocked -e called....";

            push @calls, $f;
            return 1;
        }
    );

    ok -e q[/tmp],          "/tmp exits";
    ok -e q[/do/not/exist], "/do/not/exist now exist thanks to mock=1";
    is \@calls, [qw{/tmp /do/not/exist}], 'got two calls calls';
}

{
    note "mocking a second time";

    like(
        dies {
            Overload::FileCheck::mock_file_check( '-e' => sub { 0 } )
        },
        qr/\Q-e is already mocked by Overload::FileCheck/,
        "die when mocking a second time"
    );

    Overload::FileCheck::unmock_file_check('-e');

    Overload::FileCheck::unmock_file_check(qw{-e -f});

    note "we are mocking -e => 0";
    Overload::FileCheck::mock_file_check( '-e' => sub { 0 } );

    ok !-e q[/tmp], "/tmp does not exist now...";
}

done_testing;
