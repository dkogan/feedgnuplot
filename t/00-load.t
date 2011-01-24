#!/usr/bin/perl

use Test::More tests => 1;
use Test::Script::Run;

run_ok( 'feedGnuplot', ['--help'], 'feedGnuplot can run');

