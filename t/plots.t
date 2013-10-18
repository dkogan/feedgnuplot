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
use Test::Script::Run 'is_script_output';
use File::Temp 'tempfile';


tryplot( [], 'seq 5', <<'EOF' );


    5 ++--+---+--+---+---+---+--+--+A
      +   +   +  +   +   +   +  +  *+
      |                           * |
      |                           * |
  4.5 ++                         * ++
      |                         *   |
      |                        *    |
      |                        *    |
      |                       *     |
    4 ++                     A     ++
      |                     *       |
      |                    *        |
      |                   *         |
  3.5 ++                 *         ++
      |                 *           |
      |                *            |
      |               *             |
    3 ++             A             ++
      |             *               |
      |            *                |
      |            *                |
      |           *                 |
  2.5 ++         *                 ++
      |         *                   |
      |         *                   |
      |        *                    |
    2 ++      A                    ++
      |      *                      |
      |     *                       |
      |    *                        |
      |   *                         |
  1.5 ++  *                        ++
      |  *                          |
      | *                           |
      +*  +   +  +   +   +   +  +   +
    1 A+--+---+--+---+---+---+--+--++
      1  1.5  2 2.5  3  3.5  4 4.5  5

EOF







sub tryplot
{
  my $extraoptions = shift;
  my $incmd        = shift;
  my $ref          = shift;

  my ($fh, $input_filename) = tempfile( UNLINK => 1);
  open IN, '-|', $incmd;
  print $fh <IN>;
  close IN;
  close $fh;

  my @options = (qw(--lines --points --exit),
                 '--extracmds', 'unset grid',
                 '--terminal', 'dumb 40,40',
                 $input_filename);

  unshift @options, @$extraoptions;

  is_script_output( 'feedgnuplot', \@options,
                    [$ref =~ /(.*)\n/g], [],
                    'basic line plot');
}
