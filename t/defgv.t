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

mock_all_file_checks( \&dash_check );

my $last_call;

sub dash_check {
    my ( $check, $file_or_fh ) = @_;

    $last_call = [@_];

    note "call ? ", $check, " f: ", $file_or_fh;

    return FALLBACK_TO_REAL_OP unless $check =~ qr{^[def]$};

    if ( defined $file_or_fh && $file_or_fh eq '/fake/path' ) {
        return CHECK_IS_FALSE if $check eq 'f';
        return CHECK_IS_TRUE;
    }

    return FALLBACK_TO_REAL_OP;
}

ok -e '/fake/path', '-e';
is $last_call, [ 'e', '/fake/path' ], 'last_call';

ok -d '/fake/path', '-d';
is $last_call, [ 'd', '/fake/path' ], 'last_call';

ok !-f '/fake/path', '!-f';
is $last_call, [ 'f', '/fake/path' ], 'last_call';

ok -e '/fake/path', '-e';
is $last_call, [ 'e', '/fake/path' ], 'last_call';

ok -d _, 'can use -d _';
is $last_call, [ 'd', '/fake/path' ], 'last_call' or die;

ok -e '/fake/path' && -d _, "-e && -d _";
is $last_call, [ 'd', '/fake/path' ], 'last_call' or die;

unmock_all_file_checks();

done_testing;
