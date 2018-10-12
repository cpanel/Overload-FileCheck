#!/usr/bin/perl -w

use strict;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Overload::FileCheck qw{mock_file_check unmock_file_check unmock_all_file_checks};
#use Overload::FileCheck q{:all};

my $not_there = q{/should/not/be/there}; # improve

ok( !-e $not_there, "-e 'not_there' file is missing when unmocked" );
ok( !-f $not_there, "-f 'not_there' file is missing when unmocked" );

mock_file_check( 'e' => sub { 1 } );
ok( -e $not_there, "-e 'not_there' missing file exists when mocked" );
ok( !-f $not_there, "-f 'not_there' still false" );

done_testing;
