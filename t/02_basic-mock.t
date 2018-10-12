#!/usr/bin/perl -w

use strict;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck;

#use Overload::FileCheck '-e' => \&my_dash_e;

my @calls;

{
    note "no mocks at this point";

    ok -e q[/tmp],           "/tmp/exits";
    ok !-e q[/do/not/exist], "/do/not/exist";
    is \@calls, [], 'no calls';
}

{
    note "we are mocking -e => 1";
    Overload::FileCheck::mock_file_check( '-e' => sub {
        my $f = shift;

        note "mocked -e called....";

        push @calls, $f;
        return 1;
      } );

    ok -e q[/tmp],          "/tmp exits";
    ok -e q[/do/not/exist], "/do/not/exist now exist thanks to mock=1";
    is \@calls, [qw{/tmp /do/not/exist}], 'got two calls calls';
}

{
    note "mocking a second time";

    like(
        dies {
            Overload::FileCheck::mock_file_check( '-e' => sub {0} )
        },
        qr/\Q-e is already mocked by Overload::FileCheck/,
        "die when mocking a second time"
    );

    Overload::FileCheck::unmock_file_check('-e');

    Overload::FileCheck::unmock_file_check(qw{-e -f});

    note "we are mocking -e => 0";
    Overload::FileCheck::mock_file_check( '-e' => sub {0} );

    ok !-e q[/tmp], "/tmp does not exist now...";

}

done_testing;
