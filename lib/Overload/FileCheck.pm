package Overload::FileCheck;

use strict;
use warnings;

#use Carp;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION );


# hash for every filecheck we can mock
#   and their corresonding OP_TYPE
my %MAP_FC_OP = (
    'e' => Overload::FileCheck::OP_FTIS(),
    'f' => Overload::FileCheck::OP_FTFILE(),
    # ...
);

# this is saving our custom ops
# optype_id => sub
my $_current_mocks = {};

sub import {


}

sub mock {
    my ( $check, $sub ) = @_;

    die q[Check is not defined] unless defined $check;
    die q[Second arg must be a CODE ref] unless ref $sub eq 'CODE';

    $check =~ s{^-+}{}; # strip any extra dashes
    die qq[Unknown check '$check'] unless defined $MAP_FC_OP{$check};

    my $optype = $MAP_FC_OP{$check};
    die qq[-$check is already mocked by Overload::FileCheck] if exists $_current_mocks->{$optype};
  
    $_current_mocks->{$optype} = $sub;

    _mock_ftOP( $optype  ); # XS code

    return 1;
}

sub unmock {
  my ( @checks ) = @_;

  foreach my $check ( @checks ) {
    die q[Check is not defined] unless defined $check;
    $check =~ s{^-+}{}; # strip any extra dashes
    die qq[Unknown check '$check'] unless defined $MAP_FC_OP{$check};

    my $optype = $MAP_FC_OP{$check};

    delete $_current_mocks->{$optype};
  
    _unmock_ftOP( $optype ); # XS code
  }

  return;
}

sub unmock_all {
  
  my @mocks = sort keys %$_current_mocks;
  return unless scalar @mocks;
  unmock( @mocks );

  return;
}

sub _check {
  my ( $optype, $file, @others ) = @_;

  die if scalar @others; # need to move this in a unit test

  # we have no custom mock at this point
  return -1 unless defined $_current_mocks->{$optype};

  my $out = $_current_mocks->{$optype}->( $file );

  return 0 unless $out;
  return -1 if $out == -1;
  return 1;
}

# accessors for testing purpose mainly
sub _get_filecheck_ops_map {
  return { %MAP_FC_OP }; # return a copy
}

=pod

use Overload::FileCheck '-e' => \&my_dash_e;

or 

use Overload::FileCheck ();

Overload::FileCheck::mock( '-e' => sub { 1 } );

Overload::FileCheck::unmock( qw{-e -f} );
Overload::FileCheck::unmock_all( qw{-e -f} );

=cut

1;

__END__
sub import
{
   my $class = shift;
   my %args = @_;

   my $package = caller;

   my $substr = delete $args{substr};
   defined $substr or $substr = "_substr";

   keys %args and
      croak "Unrecognised extra keys to $class: " . join( ", ", sort keys %args );

   no strict 'refs';

   unless( ref $substr ) {
      $substr = \&{$package."::$substr"};
   }

   # This somewhat steps on overload.pm 's toes
   *{$package."::(substr"} = $substr;
}

