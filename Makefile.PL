use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile
  (
   NAME                       => 'feedGnuplot',
   AUTHOR                     => q{Dima Kogan <dkogan@cds.caltech.edu>},
   VERSION_FROM               => 'bin/feedGnuplot',
   ABSTRACT_FROM              => 'bin/feedGnuplot',
   ($ExtUtils::MakeMaker::VERSION >= 6.3002
    ? ('LICENSE'              => 'perl')
    : ()),
   PL_FILES                   => {},
   EXE_FILES                  => [ 'bin/feedGnuplot' ],
   PREREQ_PM                  => { 'Test::Script::Run' => 0 },
   dist                       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
   clean                      => { FILES => 'feedGnuplot-*' },
  );

