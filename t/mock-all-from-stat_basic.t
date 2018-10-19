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
use Carp;

my $fake_files = {

    "$0"           => fake_stat_for_dollar_0(),
    'fake.binary'  => stat_for_a_binary(),
    'fake.tty'     => stat_for_a_tty(),
    'fake.dir'     => stat_for_a_directory(),
    'a.symlink'    => stat_for_a_symlink(),
    'zero'         => fake_stat_zero(),
    'regular.file' => stat_for_regular_file(),
    'my.socket'    => stat_for_socket(),
};

ok mock_all_from_stat( \&my_stat );

# move to DATA
foreach my $l (<DATA>) {
    chomp $l;
    if ( $l =~ s{^\s*#}{} ) {
        note $l;
        next;
    }

    next unless $l =~ qr{^[!-]};
    ok eval $l, $l;
}

done_testing;

exit;

sub my_stat {
    my ( $opname, $f ) = @_;

    #note "=== my_stat is called. Type: ", $opname, " File: ", $f;

    # check if it's mocked
    if ( defined $f && defined $fake_files->{$f} ) {

        #note "fake_file is known for $f";
        return $fake_files->{$f};
    }

    return FALLBACK_TO_REAL_OP();
}

sub fake_stat_zero {
    return [ (0) x 13 ];
}

sub stat_for_regular_file {
    return [
        64769,
        69887159,
        33188,
        1,
        0,
        0,
        0,
        13,
        1539928982,
        1539716940,
        1539716940,
        4096,
        8
    ];
}

sub fake_stat_for_dollar_0 {
    return [
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
    ];
}

sub stat_for_a_directory {
    return [
        64769,
        67149975,
        16877,
        23,
        0,
        0,
        0,
        4096,
        1539271725,
        1524671853,
        1524671853,
        4096,
        8,
    ];
}

sub stat_for_a_symlink {
    return [
        64769,
        180,
        41471,
        1,
        0,
        0,
        0,
        7,
        1539897601,
        1406931830,
        1406931830,
        4096,
        0,
    ];
}

sub stat_for_a_binary {
    return [
        64769,
        33728572,
        33261,
        1,
        0,
        0,
        0,
        28920,
        1539797896,
        1523421302,
        1526572488,
        4096,
        64,
    ];
}

sub stat_for_a_tty {
    return [
        5,
        1043,
        8592,
        1,
        0,
        5,
        1025,
        0,
        1538428544,
        1538428544,
        1538428550,
        4096,
        0,
    ];
}

sub stat_for_socket {
    return [
        64769,
        44067096,
        49663,
        1,
        997,
        996,
        0,
        0,
        1539898201,
        1538428546,
        1538428546,
        4096,
        0
    ];
}

__DATA__
###
### test data: all lines are tests which are run sequentially
###

# a directory
-e 'fake.dir'
-d 'fake.dir'
!-f 'fake.dir'
!-c 'fake.dir'
!-l 'fake.dir'
!-S 'fake.dir'
!-b 'fake.dir'
-r 'fake.dir'
-x 'fake.dir'

# regular file
-e 'regular.file'
-f 'regular.file'
!-d 'regular.file'
!-l 'regular.file'
-s 'regular.file'
!-z 'regular.file'
!-S 'regular.file'
!-b 'regular.file'
!-c 'regular.file'

# a binary
-e 'fake.binary'
-f 'fake.binary'
!-l 'fake.binary'
-x 'fake.binary'
!-S 'fake.binary'
!-d 'fake.binary'

# a symlink
-e 'a.symlink'
!-f 'a.symlink'
-l 'a.symlink'
!-d 'a.symlink'
!-S 'a.symlink'
!-z 'a.symlink'

# a Socket
-e 'my.socket'
!-d 'my.socket'
!-f 'my.socket'
-S 'my.socket'
!-s 'my.socket'

# a zero stat
### ... note maybe -e should fail ?
-e 'zero'
!-f 'zero'
!-l 'zero'
!-d 'zero'
-z 'zero'

# checking _ on a directory
-e 'fake.dir'
-d _
!-l _
-s _
!-S _
# checking some oneliners
-e 'fake.dir' && -d _
-d 'fake.dir' && -e _
!(-d 'fake.dir' && -f _)
-d 'fake.dir' && !-f _
-d 'fake.dir' && -d _
-e 'fake.dir' && -d _ && -s _


# checking _ on a file
-e 'regular.file'
-f _
!-d _
!-l _
-s _
!-z _
!-S _
# checking some oneliners
-e 'regular.file' && -f _
-f 'regular.file' && -e _
!( -e 'regular.file' && -d _ )
-e 'regular.file' && !-d _
!-d 'regular.file' && -e _ && -f _
-f 'regular.file' && -f _ && -f _ && -f _ && -f _ && -f _ && -f _ && -f _
