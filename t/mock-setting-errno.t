#!/usr/bin/perl -w

use strict;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck;

{
    note "no mocks at this point";

    ok -e q[/tmp],           "/tmp/exits";
    ok !-e q[/do/not/exist], "/do/not/exist";

    my $check     = -e q[/do/not/exist];
    my $errno_str = "$!";
    my $errno_int = int($!);

    ok !$check, "file does not exist";
    like $errno_str, qr{No such file or directory}, q[ERRNO set to "No such file or directory"];
    is $errno_int, 2, "ERRNO int value set";
}

{
    note "Try to override errno";
    local $!;

    note "we are mocking -e => 1";
    Overload::FileCheck::mock_file_check(
        '-e' => sub {
            my $f = shift;
            note "mocked -e called....";

            $! = 4;    # set errno

            return 0;
        }
    );

    my $check     = -e q[/tmp];
    my $errno_str = "$!";
    my $errno_int = int($!);

    ok !$check, "/tmp does not exist";
    like $errno_str, qr{Interrupted system call}, q[ERRNO set to "Interrupted system call"];
    is $errno_int, 4, "ERRNO int value set to 4";
}

done_testing;
