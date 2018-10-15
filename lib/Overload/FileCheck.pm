package Overload::FileCheck;

use strict;
use warnings;

# ABSTRACT: override/mock perl file checks ops

use XSLoader ();
use Exporter ();

our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(mock_file_check unmock_file_check unmock_all_file_checks);
our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

XSLoader::load(__PACKAGE__);

# hash for every filecheck we can mock
#   and their corresonding OP_TYPE
my %MAP_FC_OP = (
    'R' => OP_FTRREAD(),
    'W' => OP_FTRWRITE(),
    'X' => OP_FTREXEC(),
    'r' => OP_FTEREAD(),
    'w' => OP_FTEWRITE(),
    'x' => OP_FTEEXEC(),

    'e' => OP_FTIS(),
    's' => OP_FTSIZE(),
    'M' => OP_FTMTIME(),
    'C' => OP_FTCTIME(),
    'A' => OP_FTATIME(),

    'O' => OP_FTROWNED(),
    'o' => OP_FTEOWNED(),
    'z' => OP_FTZERO(),
    'S' => OP_FTSOCK(),
    'c' => OP_FTCHR(),
    'b' => OP_FTBLK(),
    'f' => OP_FTFILE(),
    'd' => OP_FTDIR(),
    'p' => OP_FTPIPE(),
    'u' => OP_FTSUID(),
    'g' => OP_FTSGID(),
    'k' => OP_FTSVTX(),

    'l' => OP_FTLINK(),

    't' => OP_FTTTY(),

    'T' => OP_FTTEXT(),
    'B' => OP_FTBINARY(),
);

my %REVERSE_MAP;

# this is saving our custom ops
# optype_id => sub
my $_current_mocks = {};

sub import {

    # do stuff there...

    # callback the exporter logic
    __PACKAGE__->export_to_level( 1, @_ );
}

sub mock_file_check {
    my ( $check, $sub ) = @_;

    die q[Check is not defined] unless defined $check;
    die q[Second arg must be a CODE ref] unless ref $sub eq 'CODE';

    $check =~ s{^-+}{};    # strip any extra dashes
                           #return -1 unless defined $MAP_FC_OP{$check}; # we should not do that
    die qq[Unknown check '$check'] unless defined $MAP_FC_OP{$check};

    my $optype = $MAP_FC_OP{$check};
    die qq[-$check is already mocked by Overload::FileCheck] if exists $_current_mocks->{$optype};

    $_current_mocks->{$optype} = $sub;

    _xs_mock_op($optype);

    return 1;
}

sub unmock_file_check {
    my (@checks) = @_;

    foreach my $check (@checks) {
        die q[Check is not defined] unless defined $check;
        $check =~ s{^-+}{};    # strip any extra dashes
        die qq[Unknown check '$check'] unless defined $MAP_FC_OP{$check};

        my $optype = $MAP_FC_OP{$check};

        delete $_current_mocks->{$optype};

        _xs_unmock_op($optype);
    }

    return;
}

sub unmock_all_file_checks {

    if ( !scalar %REVERSE_MAP ) {
        foreach my $k ( keys %MAP_FC_OP ) {
            $REVERSE_MAP{ $MAP_FC_OP{$k} } = $k;
        }
    }

    my @mocks = sort map { $REVERSE_MAP{$_} } keys %$_current_mocks;
    return unless scalar @mocks;
    unmock_file_check(@mocks);

    return;
}

sub _check {
    my ( $optype, $file, @others ) = @_;

    die if scalar @others;    # need to move this in a unit test

    # we have no custom mock at this point
    return -1 unless defined $_current_mocks->{$optype};

    my $out = $_current_mocks->{$optype}->($file);

    return 0 unless $out;
    return -1 if $out == -1;
    return 1;
}

# accessors for testing purpose mainly
sub _get_filecheck_ops_map {
    return {%MAP_FC_OP};    # return a copy
}

1;

=pod

=encoding utf8

=head1 NAME

Overload::FileCheck - override/mock perl filecheck

=begin HTML

<p><img src="https://travis-ci.org/atoomic/Overload-FileCheck.svg?branch=released" width="81" height="18" alt="Travis CI" /></p>

=end HTML

=head1 SYNOPSIS

  use Overload::FileCheck '-e' => \&my_dash_e;

  # or

  use Overload::FileCheck qw{mock_file_check unmock_file_check unmock_all_file_checks};

  # all -f checks will be true from now
  mock_file_check( '-f' => sub { 1 } );

  # mock all calls to -e and delegate to the function dash_e
  mock_file_check( '-e' => \&dash_e );

  # example of your own callback function to mock -e
  # when returning
  #  0: the test is false
  #  1: the test is true
  # -1: you want to use the answer from Perl itself :-)

  sub dash_e {
        my ( $file_or_handle ) = @_;

        # return true on -e for this specific file
        return 1 if $file eq '/this/file/is/not/there/but/act/like/if/it/was';

        # claim that /tmp is not available even if it exists
        if ( $file eq '/tmp' ) {
          $! = 2; # set errno to "No such file or directory"
          return 0;
        }

        # delegate the answer to the Perl CORE -e OP
        #   as we do not want to control these files
        return -1;
  }

  # unmock -e and -f
  unmock_file_check( '-e' );
  unmock_file_check( '-f' );
  unmock_file_check( qw{-e -f} );

  # or unmock all existing filecheck
  unmock_all_file_checks();


=head1 DESCRIPTION

Overload::FileCheck provides a hook system to mock PErl filechecks OPs

With this module you can provide your own pure perl code when performing
file checks using on of the -X ops: -e, -f, -z, ...

https://perldoc.perl.org/functions/-X.html

    -r  File is readable by effective uid/gid.
    -w  File is writable by effective uid/gid.
    -x  File is executable by effective uid/gid.
    -o  File is owned by effective uid.
    -R  File is readable by real uid/gid.
    -W  File is writable by real uid/gid.
    -X  File is executable by real uid/gid.
    -O  File is owned by real uid.
    -e  File exists.
    -z  File has zero size (is empty).
    -s  File has nonzero size (returns size in bytes).
    -f  File is a plain file.
    -d  File is a directory.
    -l  File is a symbolic link (false if symlinks aren't
        supported by the file system).
    -p  File is a named pipe (FIFO), or Filehandle is a pipe.
    -S  File is a socket.
    -b  File is a block special file.
    -c  File is a character special file.
    -t  Filehandle is opened to a tty.
    -u  File has setuid bit set.
    -g  File has setgid bit set.
    -k  File has sticky bit set.
    -T  File is an ASCII or UTF-8 text file (heuristic guess).
    -B  File is a "binary" file (opposite of -T).
    -M  Script start time minus file modification time, in days.
    -A  Same for access time.
    -C  Same for inode change time (Unix, may differ for other
  platforms)


Also view pp_sys.c from the Perl source code, where are defined the original OPs.

=head1 Usage

When using this module, you can decide to mock filecheck OPs on import or later
at run time.

=head2 Mocking filecheck at import time

    use Overload::FileCheck '-e' => \&my_dash_e, -f => sub { 1 };

    # example of your own callback function to mock -e
    # when returning
    #  0: the test is false
    #  1: the test is true
    # -1: you want to use the answer from Perl itself :-)

    sub dash_e {
          my ( $file_or_handle ) = @_;

          # return true on -e for this specific file
          return 1 if $file eq '/this/file/is/not/there/but/act/like/if/it/was';

          # claim that /tmp is not available even if it exists
          return 0 if $file eq '/tmp';

          # delegate the answer to the Perl CORE -e OP
          #   as we do not want to control these files
          return -1;
      }

=head2 Mocking filecheck at run time

You can also get a similar behavior by declaring the overload later at run time.


    use Overload::FileCheck (); # no import

    Overload::FileCheck::mock_file_check( '-e' => \&my_dash_e );
    Overload::FileCheck::mock_file_check( '-f' => sub { 1 } );

    # example of your own callback function to mock -e
    # when returning
    #  0: the test is false
    #  1: the test is true
    # -1: you want to use the answer from Perl itself :-)

    sub dash_e {
          my ( $file_or_handle ) = @_;

          # return true on -e for this specific file
          return 1 if $file eq '/this/file/is/not/there/but/act/like/if/it/was';

          # claim that /tmp is not available even if it exists
          return 0 if $file eq '/tmp';

          # delegate the answer to the Perl CORE -e OP
          #   as we do not want to control these files
          return -1;
      }

=head1 Available functions

=head2 mock_file_check( $check, $CODE )

mock_file_check function is used to mock one of the filecheck op.

The first argument is one of the file check: '-f', '-e', ... where the dash is optional.
It also accepts 'e', 'f', ...

When trying to mock a filecheck already mocked, the function will die with an error like

  -f is already mocked by Overload::FileCheck

This would guarantee that you are not mocking multiple times the same filecheck in your codebase.

Otherwise returns 1 on success.

  # this is probably a very bad idea to do this in your codebase
  # but can be useful for some testing
  # in that sample all '-e' checks will always return true...
  mock_file_check( '-e' => sub { 1 } )

=head2 unmock_file_check( $check, [@extra_checks] )

Disable the effect of one or more specific mock.
The argument to unmock_file_check can be a list or a single scalar value.
The leading dash is optional.

  unmock_file_check( '-e' );
  unmock_file_check( 'e' );            # also work without the dash
  unmock_file_check( qw{-e -f -z} );
  unmock_file_check( qw{e f} );        # also work without the dashes

=head2 unmock_all_file_checks()

By a simple call to unmock_all_file_checks, you would disable the effect of overriding the
filecheck OPs. (not that the XS code is still plugged in, but fallback as soon
as possible to the original OP)


=head1 Notice

This is a very early development stage and some behavior might change before the release of a more stable build.


=head1 LICENSE

This software is copyright (c) 2018 by cPanel, Inc.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming
language system itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY
APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE
OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING,
REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY
WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS
BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

