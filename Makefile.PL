#!/bin/env perl

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Overload::FileCheck',
    'VERSION_FROM' => 'lib/Overload/FileCheck.pm',
    'PREREQ_PM'    => {
        'Test::More'      => 0,
        'Test::Exception' => 0
    },

    AUTHOR   => 'Nicolas R. <atoomic@cpan.org>',
    'LIBS'   => [''],
    'DEFINE' => '',
    'INC'    => '-I.'
);
