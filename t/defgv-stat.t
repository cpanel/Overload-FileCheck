#!/usr/bin/perl -w

# Copyright (c) 2018, cPanel, LLC.
# All rights reserved.
# http://cpanel.net
#
# This is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself. See L<perlartistic>.

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck q{:all};

# unmocked

{
    my $s    = [ stat("/") ];
    my $name = Overload::FileCheck::get_statname();
    is $name, '/', "get_statname is set to / - unmocked";
}

{
    my $s    = [ stat($0) ];
    my $name = Overload::FileCheck::get_statname();
    is $name, $0, q[get_statname is set to $0 - unmocked];

}

{
    -e '/';
    is Overload::FileCheck::get_statname(), '/', q[get_statname back to / after -e - unmocked];
}

mock_all_from_stat( \&my_stat );

my $last_call;

sub my_stat {
    my ( $stat_or_lstat, $f_or_fh ) = @_;

    $last_call = [@_];

    return stat_as_directory();
}

{
    my $s = [ stat("/") ];
    is Overload::FileCheck::get_statname(), '/', "get_statname is set to / - mocked";

    is $last_call, [ 'stat', '/' ], 'stat / was called';

    $last_call = [];
    ok -d _, '-d _';
    is $last_call, [ 'lstat', '/' ], 'stat called to check the symlink';
    is Overload::FileCheck::get_statname(), '/', 'statname is still set';
}

{
    my $s = [ stat($0) ];
    if ( $] >= 5.018 ) {
        is Overload::FileCheck::get_statname(), $0, q[get_statname is set to $0 - mocked];
    }
    else {
        todo "statname not set <= 5.016..." => sub {
            is Overload::FileCheck::get_statname(), $0, q[get_statname is set to $0 - mocked];
        };
    }

    ok -d _, q[we mocked stat and mark $0 as a dir];
}

unmock_all_file_checks();

done_testing;
