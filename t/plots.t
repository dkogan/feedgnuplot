#!/usr/bin/perl

# This tests various features of feedgnuplot. Note that the tests look at actual
# plot output using the 'dumb' terminal, so any changes in gnuplot itself that
# change the way the output looks will show up as test failures. Hopefully this
# will not be a big deal


# require a threaded perl for my tests. This block lifted verbatim from the cpantesters wiki
BEGIN {
  use Config;
  if (! $Config{'useithreads'}) {
    print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
    exit(0);
  }
}

use Test::More tests => 16;
use Test::Script::Run 'is_script_output';
use File::Temp 'tempfile';

tryplot( testname => 'basic line plot',
         cmd      => 'seq 5',
         options  => [qw(--lines --points)],
         refplot  => <<'EOF' );


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

tryplot( testname => 'basic line plot to piped hardcopy',
         cmd      => 'seq 5',
         options  => [qw(--lines --points),
                      '--hardcopy', '|cat'],
         refplot  => <<'EOF' );


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

Wrote output to |cat
EOF

tryplot( testname => 'basic lines-only plot',
         cmd      => 'seq 5',
         options  => [qw(--lines)],
         refplot  => <<'EOF' );


    5 ++--+---+--+---+---+---+--+--+*
      +   +   +  +   +   +   +  +  *+
      |                           * |
      |                           * |
  4.5 ++                         * ++
      |                         *   |
      |                        *    |
      |                        *    |
      |                       *     |
    4 ++                     *     ++
      |                     *       |
      |                    *        |
      |                   *         |
  3.5 ++                 *         ++
      |                 *           |
      |                *            |
      |               *             |
    3 ++             *             ++
      |             *               |
      |            *                |
      |            *                |
      |           *                 |
  2.5 ++         *                 ++
      |         *                   |
      |         *                   |
      |        *                    |
    2 ++      *                    ++
      |      *                      |
      |     *                       |
      |    *                        |
      |   *                         |
  1.5 ++  *                        ++
      |  *                          |
      | *                           |
      +*  +   +  +   +   +   +  +   +
    1 *+--+---+--+---+---+---+--+--++
      1  1.5  2 2.5  3  3.5  4 4.5  5

EOF

tryplot( testname => 'basic points-only plot',
         cmd      => 'seq 5',
         options  => [qw(--points)],
         refplot  => <<'EOF' );


    5 ++--+---+--+---+---+---+--+--+A
      +   +   +  +   +   +   +  +   +
      |                             |
      |                             |
  4.5 ++                           ++
      |                             |
      |                             |
      |                             |
      |                             |
    4 ++                     A     ++
      |                             |
      |                             |
      |                             |
  3.5 ++                           ++
      |                             |
      |                             |
      |                             |
    3 ++             A             ++
      |                             |
      |                             |
      |                             |
      |                             |
  2.5 ++                           ++
      |                             |
      |                             |
      |                             |
    2 ++      A                    ++
      |                             |
      |                             |
      |                             |
      |                             |
  1.5 ++                           ++
      |                             |
      |                             |
      +   +   +  +   +   +   +  +   +
    1 A+--+---+--+---+---+---+--+--++
      1  1.5  2 2.5  3  3.5  4 4.5  5

EOF

tryplot( testname => 'basic line plot with bounds',
         cmd      => 'seq 5',
         options  => [qw(--lines --points),
                      qw(--xmin -10.5 --xmax 4.5 --ymin -0.5 --ymax 5.5)],
         refplot  => <<'EOF' );


    ++---+----+---+---+---+----+---++
    |+   +    +   +   +   +    +   +|
    |                               |
  5 ++                             ++
    |                               |
    |                               |
    |                               *
    |                               *
    |                              *|
  4 ++                             A+
    |                              *|
    |                             * |
    |                             * |
    |                             * |
    |                            *  |
  3 ++                           A ++
    |                            *  |
    |                           *   |
    |                           *   |
    |                          *    |
  2 ++                         A   ++
    |                          *    |
    |                         *     |
    |                         *     |
    |                         *     |
    |                        *      |
  1 ++                       A     ++
    |                               |
    |                               |
    |                               |
    |                               |
    |                               |
  0 ++                             ++
    |                               |
    |+   +    +   +   +   +    +   +|
    ++---+----+---+---+---+----+---++
    -10 -8   -6  -4  -2   0    2   4

EOF

tryplot( testname => 'basic line plot with bounds, square aspect ratio',
         cmd      => 'seq 5',
         options  => [qw(--lines --points),
                      qw(--xmin -10.5 --xmax 4.5 --ymin -0.5 --ymax 5.5 --square)],
         refplot  => <<'EOF' );













    ++---+----+---+---+---+----+---++
  5 ++   +    +   +   +   +    +   ++
    |                               *
  4 ++                             A+
    |                             * |
  3 ++                           A ++
    |                           *   |
    |                           *   |
  2 ++                         A   ++
    |                         *     |
  1 ++                       A     ++
    |                               |
  0 ++   +    +   +   +   +    +   ++
    ++---+----+---+---+---+----+---++
    -10 -8   -6  -4  -2   0    2   4












EOF

tryplot( testname => 'lines on both axes with labels, legends, titles',
         cmd      => q{seq 5 | awk '{print 2*$1, $1*$1}'},
         options  => [qw(--lines --points),
                      '--legend', '0', 'data 0',
                      '--title', "Test plot",
                      qw(--y2 1 --y2label y2 --xlabel x --ylabel y --y2max 30)],
         refplot  => <<'EOF' );

              Test plot
                                  y2
  10 ++-+---+--+--+--+---+--+-+A 30
     +  +   +  +  +  +   +  + *+
     |           data 0 **A****|
     |                       * |
   9 ++                     *  |
     |                     *  +B 25
     |                     *  #|
     |                    *   #|
   8 ++                  A   # |
     |                  *    # |
     |                 *    #  |
     |                *    #  ++ 20
   7 ++               *    #   |
     |               *    #    |
     |              *     #    |
     |             *     B     |
   6 ++           A     #     ++ 15
     |           *     #       |
     |           *    #        |
     |          *     #        |
     |         *     #         |
   5 ++        *    #          |
     |        *    #          ++ 10
     |       *    B            |
     |       *   #             |
   4 ++     A   #              |
     |     *   #               |
     |    *   #               ++ 5
     |   *   #                 |
   3 ++  * #B                  |
     |  *##                    |
     | *#                      |
     B* +   +  +  +  +   +  +  +
   2 A+-+---+--+--+--+---+--+-++ 0
     1 1.5  2 2.5 3 3.5  4 4.5 5
                  x

EOF

tryplot( testname => 'lines on both axes with labels, legends, titles; different styles',
         cmd      => q{seq 5 | awk '{print 2*$1, $1*$1}'},
         options  => ['--legend', '0', 'data 0',
                      '--title', "Test plot",
                      qw(--y2 1 --y2label y2 --xlabel x --ylabel y --y2max 30),
                      '--curvestyle', '0', 'with lines',
                      '--curvestyle', '1', 'with points ps 3 pt 7'],
         refplot  => <<'EOF' );

              Test plot
                                  y2
  10 ++-+---+--+--+--+---+--+-+* 30
     +  +   +  +  +  +   +  + *+
     |           data 0 *******|
     |                       * |
   9 ++                     *  |
     |                     *  +G 25
     |                     *   |
     |                    *    |
   8 ++                  *     |
     |                  *      |
     |                 *       |
     |                *       ++ 20
   7 ++               *        |
     |               *         |
     |              *          |
     |             *     G     |
   6 ++           *           ++ 15
     |           *             |
     |           *             |
     |          *              |
     |         *               |
   5 ++        *               |
     |        *               ++ 10
     |       *    G            |
     |       *                 |
   4 ++     *                  |
     |     *                   |
     |    *                   ++ 5
     |   *                     |
   3 ++  *  G                  |
     |  *                      |
     | *                       |
     G* +   +  +  +  +   +  +  +
   2 *+-+---+--+--+--+---+--+-++ 0
     1 1.5  2 2.5 3 3.5  4 4.5 5
                  x

EOF

tryplot( testname => 'domain plot',
         cmd      => q{seq 5 | awk '{print 2*$1, $1*$1}'},
         options  => [qw(--lines --points), '--domain'],
         refplot  => <<'EOF' );


  25 ++--+---+---+---+--+---+---+--+A
     +   +   +   +   +  +   +   +  *+
     |                             *|
     |                            * |
     |                            * |
     |                           *  |
     |                          *   |
  20 ++                         *  ++
     |                         *    |
     |                        *     |
     |                        *     |
     |                       *      |
     |                       *      |
     |                      A       |
  15 ++                    *       ++
     |                    *         |
     |                    *         |
     |                   *          |
     |                  *           |
     |                 *            |
     |                 *            |
  10 ++               *            ++
     |               A              |
     |              *               |
     |             *                |
     |           **                 |
     |          *                   |
     |         *                    |
   5 ++       *                    ++
     |       A                      |
     |     **                       |
     |   **                         |
     |  *                           |
     |**                            |
     A   +   +   +   +  +   +   +   +
   0 ++--+---+---+---+--+---+---+--++
     2   3   4   5   6  7   8   9   10

EOF

tryplot( testname => 'dataid plot',
         cmd      => q{seq 5 | awk '{print 2*$1, $1*$1}'},
         options  => [qw(--lines --points),
                      qw(--dataid --autolegend)],
         refplot  => <<'EOF' );


  25 ++--+---+---+---+--+---+---+--+E
     +   +   +   +   +  +   +   +   +
     |                     2 **A*** |
     |                     4 ##B### |
     |                     6 $$C$$$ |
     |                     8 %%D%%% |
     |                    10 @@E@@@ |
  20 ++                            ++
     |                              |
     |                              |
     |                              |
     |                              |
     |                              |
     |                      D       |
  15 ++                            ++
     |                              |
     |                              |
     |                              |
     |                              |
     |                              |
     |                              |
  10 ++                            ++
     |               C              |
     |                              |
     |                              |
     |                              |
     |                              |
     |                              |
   5 ++                            ++
     |       B                      |
     |                              |
     |                              |
     |                              |
     |                              |
     A   +   +   +   +  +   +   +   +
   0 ++--+---+---+---+--+---+---+--++
     1  1.5  2  2.5  3 3.5  4  4.5  5

EOF

tryplot( testname => '3d spiral with bounds, labels',
         cmd      => q{seq 50 | awk '{print 2*cos($1/5), sin($1/5), $1}'},
         options  => [qw(--lines --points),
                      qw(--3d --domain --zmin -5 --zmax 45 --zlabel z),
                     '--extracmds', 'set view 60,30'],
         refplot  => <<'EOF' );







               A*AA*AA*
              *        A*
                         AA
                           A
                            A
                             *
        +                    A
    40  |+    A*A*AAA*       A
        |    A        A*A*   A
    30  |+ AA             A A
        |  A               A
 z  20  |+ AA             A A
        |   AA*AA*A*AA*A*A   A
    10  |+       +-          A
        |       -+ ---       A
     0  |+     -+   + ---
        |     -+        +---
        |   --+           + ---
        |  -++                +- 1
        | -+                   0.8
        |-+                   0.6
        ++---              - 0.4
      -21.5 +---          -+ 0.2
          -1+ + +--      +-0.2
           -0.50+ +---  +-0.4
                0.51++-+-0.6
                   1.5+-1.8
                      2





EOF

tryplot( testname => '3d spiral with bounds, labels, square xy aspect ratio',
         cmd      => q{seq 50 | awk '{print 2*cos($1/5), sin($1/5), $1}'},
         options  => [qw(--lines --points),
                      qw(--3d --domain --zmin -5 --zmax 45 --zlabel z),
                     '--extracmds', 'set view 60,30', '--square_xy'],
         refplot  => <<'EOF' );








             *AA*
                 AA*A
                     A
          +           A*A
      40  |+             A
          |               A
      30  |+               A
          | AAAAA*          A
   z  20  |+AA    AA        A
          |  AA*    A*A    AA
          |     AA*AAA*AA*A
      10  |+             AAA
       0  |+                A
          |                 A
          |    +-           A
          |   -++---
          | --+    +---
          |-++        +---
          +++--           ---
         -21.5+---          +- 1
             -10.5---      + 0.6
                  0 +---  +  024
                   0.5  ++-0.4
                      1.521.8








EOF

tryplot( testname => 'Histogram plot',
         cmd      => q{seq 50 | awk '{print $1*$1}'},
         options  => [qw(--lines --points),
                      qw(--histo 0 --binwidth 50 --ymin 0 --curvestyleall), 'with boxes'],
         refplot  => <<'EOF' );


    4 ++--**---+---+---+---+----+--++
      +   **   +   +   +   +    +   +
      |   **                        |
      |   **                        |
  3.5 ++  **                       ++
      |   **                        |
      |   **                        |
      |   **                        |
      |   **                        |
    3 ++  **                       ++
      |   **                        |
      |   **                        |
      |   **                        |
  2.5 ++  **                       ++
      |   **                        |
      |   **                        |
      |   **                        |
    2 ++  ****                     ++
      |   ****                      |
      |   ****                      |
      |   ****                      |
      |   ****                      |
  1.5 ++  ****                     ++
      |   ****                      |
      |   ****                      |
      |   ****                      |
    1 ++  ***********************  ++
      |   ***********************   |
      |   ***********************   |
      |   ***********************   |
      |   ***********************   |
  0.5 ++  ***********************  ++
      |   ***********************   |
      |   ***********************   |
      +   ***********************   +
    0 ++--***********************--++
    -500  0   500 100015002000 25003000

EOF

tryplot( testname => 'Cumulative histogram',
         cmd      => q{seq 50 | awk '{print $1*$1}'},
         options  => [qw(--lines --points),
                      qw(--histo 0 --histstyle cum --binwidth 50 --ymin 0 --curvestyleall), 'with boxes'],
         refplot  => <<'EOF' );


  50 ++--+----+---+----+---+---**--++
     +   +    +   +    +   +  ***   +
     |                       ****   |
     |                     ******   |
     |                    *******   |
     |                    *******   |
     |                  *********   |
  40 ++                **********  ++
     |                ***********   |
     |               ************   |
     |              *************   |
     |             **************   |
     |             **************   |
     |            ***************   |
  30 ++          ****************  ++
     |          *****************   |
     |          *****************   |
     |         ******************   |
     |         ******************   |
     |        *******************   |
     |       ********************   |
  20 ++      ********************  ++
     |      *********************   |
     |      *********************   |
     |     **********************   |
     |     **********************   |
     |     **********************   |
     |    ***********************   |
  10 ++   ***********************  ++
     |    ***********************   |
     |    ***********************   |
     |    ***********************   |
     |   ************************   |
     |   ************************   |
     +   ************************   +
   0 ++--************************--++
   -500  0   500 1000 15002000 25003000

EOF

tryplot( testname => 'Circles',
         cmd      => q{seq 5 | awk '{print $1,$1,$1/10}'},
         options  => [qw(--circles --domain)],
         refplot  => <<'EOF' );


    5 ++-+--+--+--+--+--+--+--*--+-**
      +  +  +  +  +  +  +  +  *  + *+
      |                       *    *|
      |                       ******|
  4.5 ++                           ++
      |                             |
      |                             |
      |                    *        |
      |                  ****       |
    4 ++                 *  **     ++
      |                  *  *       |
      |                  ****       |
      |                             |
  3.5 ++                           ++
      |                             |
      |              *              |
      |            ****             |
    3 ++           *  **           ++
      |            *  *             |
      |            ****             |
      |                             |
      |                             |
  2.5 ++                           ++
      |                             |
      |                             |
      |        *                    |
    2 ++      ***                  ++
      |       **                    |
      |                             |
      |                             |
      |                             |
  1.5 ++                           ++
      |                             |
      |                             |
      +  *  +  +  +  +  +  +  +  +  +
    1 ++***-+--+--+--+--+--+--+--+-++
     0.5 1 1.5 2 2.5 3 3.5 4 4.5 5 5.5

EOF

tryplot( testname => 'Error bars (using extraValuesPerPoint)',
         cmd      => q{seq 5 | awk '{print $1,$1,$1/10}'},
         options  => [qw(--domain),
                      qw(--extraValuesPerPoint 1 --curvestyle 0), 'with errorbars'],
         refplot  => <<'EOF' );


  5.5 ++--+---+--+---+---+---+--+--***
      +   +   +  +   +   +   +  +   *
      |                             *
    5 ++                           +A
      |                             *
      |                             *
      |                             *
  4.5 ++                           ***
      |                     ***     |
      |                      *      |
    4 ++                     A     ++
      |                      *      |
      |                      *      |
      |                     ***     |
  3.5 ++                           ++
      |             ***             |
      |              *              |
    3 ++             A             ++
      |              *              |
      |              *              |
      |             ***             |
  2.5 ++                           ++
      |                             |
      |      ***                    |
    2 ++      A                    ++
      |       *                     |
      |      ***                    |
      |                             |
  1.5 ++                           ++
      |                             |
      |                             |
    1*A*                           ++
     ***                            |
      |                             |
      +   +   +  +   +   +   +  +   +
  0.5 ++--+---+--+---+---+---+--+--++
      1  1.5  2 2.5  3  3.5  4 4.5  5

EOF

tryplot( testname => 'Monotonicity check',
         cmd      => q{seq 10 | awk '{print (NR-1)%5,NR}'},
         options  => [qw(--lines --points --domain --monotonic)],
         refplot  => <<'EOF' );


   10 ++--+---+--+---+---+---+--+--+A
      +   +   +  +   +   +   +  +  *+
      |                           * |
      |                           * |
  9.5 ++                         * ++
      |                         *   |
      |                        *    |
      |                        *    |
      |                       *     |
    9 ++                     A     ++
      |                     *       |
      |                    *        |
      |                   *         |
  8.5 ++                 *         ++
      |                 *           |
      |                *            |
      |               *             |
    8 ++             A             ++
      |             *               |
      |            *                |
      |            *                |
      |           *                 |
  7.5 ++         *                 ++
      |         *                   |
      |         *                   |
      |        *                    |
    7 ++      A                    ++
      |      *                      |
      |     *                       |
      |    *                        |
      |   *                         |
  6.5 ++  *                        ++
      |  *                          |
      | *                           |
      +*  +   +  +   +   +   +  +   +
    6 A+--+---+--+---+---+---+--+--++
      0  0.5  1 1.5  2  2.5  3 3.5  4

EOF

sub tryplot
{
  my %args = @_;

  my ($fh, $input_filename) = tempfile( UNLINK => 1);
  open IN, '-|', $args{cmd};
  print $fh <IN>;
  close IN;
  close $fh;

  my @options = ('--exit',
                 '--extracmds', 'unset grid',
                 '--terminal', 'dumb 40,40',
                 $input_filename);

  unshift @options, @{$args{options}};

  is_script_output( 'feedgnuplot', \@options,
                    [$args{refplot} =~ /(.*)\n/g], [],
                    $args{testname});
}
