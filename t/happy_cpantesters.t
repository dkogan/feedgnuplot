#!perl

use strict;
use Test::More tests => 1;

# Here I use my bogus package (which only exists for CPAN indexing), and make
# sure it works. This test is needless too, it just exists to satisfy CPAN
# checks

BEGIN{
    require_ok 'App::feedgnuplot';

}

diag("App::feedgnuplot/$App::feedgnuplot::VERSION");

__DATA__
