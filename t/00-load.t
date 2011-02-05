#!/usr/bin/perl

# require a threaded perl for my tests. This block lifted verbatim from the cpantesters wiki
BEGIN {
  use Config;
  if (! $Config{'useithreads'}) {
    print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
    exit(0);
  }
}

use Test::More tests => 1;
use Test::Script::Run;

run_ok( 'feedGnuplot', ['--help'], 'feedGnuplot can run');

