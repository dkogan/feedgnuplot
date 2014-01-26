#!/usr/bin/perl

# This tests various features of feedgnuplot. Note that the tests look at actual
# plot output using the 'dumb' terminal, so any changes in gnuplot itself that
# change the way the output looks will show up as test failures. Currently the
# reference plots come from gnuplot 4.6.4, and I make sure this is the version
# we're testing with
#
# Note that some tests are only executed when the RUN_ALL_TESTS environment
# variable is set.

# require a threaded perl for my tests. This block lifted verbatim from the cpantesters wiki
BEGIN {
  use Config;
  if (! $Config{'useithreads'}) {
    print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
    exit(0);
  }

  my $gawkversion = `gawk -V`;
  if( !$gawkversion || $@ )
  {
    print("1..0 # Skip: gawk is required for strftime() in the test suite. Skipping tests.\n");
    exit(0);
  }

  my $gnuplotVersion = `gnuplot --version`;
  if( !$gnuplotVersion || $@)
  {
    print("1..0 # Skip: gnuplot not installed. Tests require ver. 4.6.4; feedgnuplot works with any.\n");
    exit(0);
  }

  chomp $gnuplotVersion;
  if ($gnuplotVersion ne "gnuplot 4.6 patchlevel 4")
  {
    print("1..0 # Skip: tests require gnuplot 4.6.4. Instead I detected '$gnuplotVersion'.\n");
    exit(0);
  }
}

use Test::More tests => 52;
use File::Temp 'tempfile';
use IPC::Run 'run';
use String::ShellQuote;
use File::Basename;

tryplot( testname => 'basic line plot',
         cmd      => 'seq 5',
         options  => [qw(--lines --points)],
         refplot  => <<'EOF' );


    5 ++---------+-----------+----------+----------+----------+-----------+----------+---------*A
      +          +           +          +          +          +           +          +       ** +
      |                                                                                   ***   |
      |                                                                                 **      |
  4.5 ++                                                                             ***       ++
      |                                                                            **           |
      |                                                                          **             |
      |                                                                       ***               |
      |                                                                     **                  |
    4 ++                                                                 *A*                   ++
      |                                                               ***                       |
      |                                                            ***                          |
      |                                                         ***                             |
  3.5 ++                                                      **                               ++
      |                                                    ***                                  |
      |                                                 ***                                     |
      |                                              ***                                        |
    3 ++                                          *A*                                          ++
      |                                         **                                              |
      |                                      ***                                                |
      |                                    **                                                   |
      |                                 ***                                                     |
  2.5 ++                              **                                                       ++
      |                             **                                                          |
      |                          ***                                                            |
      |                        **                                                               |
    2 ++                    *A*                                                                ++
      |                   **                                                                    |
      |                ***                                                                      |
      |              **                                                                         |
      |           ***                                                                           |
  1.5 ++       ***                                                                             ++
      |      **                                                                                 |
      |   ***                                                                                   |
      + **       +           +          +          +          +           +          +          +
    1 A*---------+-----------+----------+----------+----------+-----------+----------+---------++
      1         1.5          2         2.5         3         3.5          4         4.5         5

EOF

tryplot( testname => 'basic line plot to piped hardcopy',
         cmd      => 'seq 5',
         options  => [qw(--lines --points),
                      '--hardcopy', '|cat'],
         refplot  => <<'EOF' );


    5 ++---------+-----------+----------+----------+----------+-----------+----------+---------*A
      +          +           +          +          +          +           +          +       ** +
      |                                                                                   ***   |
      |                                                                                 **      |
  4.5 ++                                                                             ***       ++
      |                                                                            **           |
      |                                                                          **             |
      |                                                                       ***               |
      |                                                                     **                  |
    4 ++                                                                 *A*                   ++
      |                                                               ***                       |
      |                                                            ***                          |
      |                                                         ***                             |
  3.5 ++                                                      **                               ++
      |                                                    ***                                  |
      |                                                 ***                                     |
      |                                              ***                                        |
    3 ++                                          *A*                                          ++
      |                                         **                                              |
      |                                      ***                                                |
      |                                    **                                                   |
      |                                 ***                                                     |
  2.5 ++                              **                                                       ++
      |                             **                                                          |
      |                          ***                                                            |
      |                        **                                                               |
    2 ++                    *A*                                                                ++
      |                   **                                                                    |
      |                ***                                                                      |
      |              **                                                                         |
      |           ***                                                                           |
  1.5 ++       ***                                                                             ++
      |      **                                                                                 |
      |   ***                                                                                   |
      + **       +           +          +          +          +           +          +          +
    1 A*---------+-----------+----------+----------+----------+-----------+----------+---------++
      1         1.5          2         2.5         3         3.5          4         4.5         5

Wrote output to |cat
EOF

tryplot( testname => 'basic lines-only plot',
         cmd      => 'seq 5',
         options  => [qw(--lines)],
         refplot  => <<'EOF' );


    5 ++---------+-----------+----------+----------+----------+-----------+----------+---------**
      +          +           +          +          +          +           +          +       ** +
      |                                                                                   ***   |
      |                                                                                 **      |
  4.5 ++                                                                             ***       ++
      |                                                                            **           |
      |                                                                          **             |
      |                                                                       ***               |
      |                                                                     **                  |
    4 ++                                                                 ***                   ++
      |                                                               ***                       |
      |                                                            ***                          |
      |                                                         ***                             |
  3.5 ++                                                      **                               ++
      |                                                    ***                                  |
      |                                                 ***                                     |
      |                                              ***                                        |
    3 ++                                          ***                                          ++
      |                                         **                                              |
      |                                      ***                                                |
      |                                    **                                                   |
      |                                 ***                                                     |
  2.5 ++                              **                                                       ++
      |                             **                                                          |
      |                          ***                                                            |
      |                        **                                                               |
    2 ++                    ***                                                                ++
      |                   **                                                                    |
      |                ***                                                                      |
      |              **                                                                         |
      |           ***                                                                           |
  1.5 ++       ***                                                                             ++
      |      **                                                                                 |
      |   ***                                                                                   |
      + **       +           +          +          +          +           +          +          +
    1 **---------+-----------+----------+----------+----------+-----------+----------+---------++
      1         1.5          2         2.5         3         3.5          4         4.5         5

EOF

tryplot( testname => 'basic points-only plot',
         cmd      => 'seq 5',
         options  => [qw(--points)],
         refplot  => <<'EOF' );


    5 ++---------+-----------+----------+----------+----------+-----------+----------+---------+A
      +          +           +          +          +          +           +          +          +
      |                                                                                         |
      |                                                                                         |
  4.5 ++                                                                                       ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
    4 ++                                                                  A                    ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
  3.5 ++                                                                                       ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
    3 ++                                           A                                           ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
  2.5 ++                                                                                       ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
    2 ++                     A                                                                 ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
  1.5 ++                                                                                       ++
      |                                                                                         |
      |                                                                                         |
      +          +           +          +          +          +           +          +          +
    1 A+---------+-----------+----------+----------+----------+-----------+----------+---------++
      1         1.5          2         2.5         3         3.5          4         4.5         5

EOF

tryplot( testname => 'basic line plot with bounds',
         cmd      => 'seq 5',
         options  => [qw(--lines --points),
                      qw(--xmin -10.5 --xmax 4.5 --ymin -0.5 --ymax 5.5)],
         refplot  => <<'EOF' );


    +--+-----------+------------+-----------+-----------+-----------+------------+-----------+--+
    |  +           +            +           +           +           +            +           +  |
    |                                                                                           |
  5 ++                                                                                         ++
    |                                                                                           |
    |                                                                                           |
    |                                                                                           *
    |                                                                                          *|
    |                                                                                         * |
  4 ++                                                                                       A ++
    |                                                                                       *   |
    |                                                                                      *    |
    |                                                                                     *     |
    |                                                                                    *      |
    |                                                                                   *       |
  3 ++                                                                                 A       ++
    |                                                                                 *         |
    |                                                                               **          |
    |                                                                              *            |
    |                                                                             *             |
  2 ++                                                                           A             ++
    |                                                                           *               |
    |                                                                          *                |
    |                                                                         *                 |
    |                                                                        *                  |
    |                                                                       *                   |
  1 ++                                                                     A                   ++
    |                                                                                           |
    |                                                                                           |
    |                                                                                           |
    |                                                                                           |
    |                                                                                           |
  0 ++                                                                                         ++
    |                                                                                           |
    |  +           +            +           +           +           +            +           +  |
    +--+-----------+------------+-----------+-----------+-----------+------------+-----------+--+
      -10         -8           -6          -4          -2           0            2           4

EOF

tryplot( testname => 'basic line plot with bounds, square aspect ratio',
         cmd      => 'seq 5',
         options  => [qw(--lines --points),
                      qw(--xmin -10.5 --xmax 4.5 --ymin -0.5 --ymax 5.5 --square)],
         refplot  => <<'EOF' );


      +--+-----------+----------+-----------+-----------+-----------+----------+-----------+--+
      |  +           +          +           +           +           +          +           +  |
      |                                                                                       |
    5 ++                                                                                     ++
      |                                                                                       |
      |                                                                                       |
      |                                                                                       *
      |                                                                                      *|
      |                                                                                     * |
    4 ++                                                                                   A ++
      |                                                                                   *   |
      |                                                                                  *    |
      |                                                                                 *     |
      |                                                                                *      |
      |                                                                               *       |
    3 ++                                                                             A       ++
      |                                                                             *         |
      |                                                                           **          |
      |                                                                          *            |
      |                                                                         *             |
    2 ++                                                                       A             ++
      |                                                                       *               |
      |                                                                      *                |
      |                                                                     *                 |
      |                                                                    *                  |
      |                                                                   *                   |
    1 ++                                                                 A                   ++
      |                                                                                       |
      |                                                                                       |
      |                                                                                       |
      |                                                                                       |
      |                                                                                       |
    0 ++                                                                                     ++
      |                                                                                       |
      |  +           +          +           +           +           +          +           +  |
      +--+-----------+----------+-----------+-----------+-----------+----------+-----------+--+
        -10         -8         -6          -4          -2           0          2           4

EOF

tryplot( testname => 'lines on both axes with labels, legends, titles',
         cmd      => q{seq 5 | gawk '{print 2*$1, $1*$1}'},
         options  => [qw(--lines --points),
                      '--legend', '0', 'data 0',
                      '--title', "Test plot",
                      qw(--y2 1 --y2label y2 --xlabel x --ylabel y --y2max 30)],
         refplot  => <<'EOF' );

                                            Test plot
                                                                                              y2
  10 ++---------+----------+---------+----------+----------+----------+---------+---------*A 30
     +          +          +         +          +          +          +      data 0 **A*** +
     |                                                                               ***   |
     |                                                                            ***      |
   9 ++                                                                         **         |
     |                                                                       ***          #B 25
     |                                                                    ***           ## |
     |                                                                  **            ##   |
   8 ++                                                              *A*            ##     |
     |                                                            ***             ##       |
     |                                                          **              ##         |
     |                                                       ***              ##          ++ 20
   7 ++                                                   ***               ##             |
     |                                                 ***                ##               |
     |                                               **                 ##                 |
     |                                            ***                #B#                   |
   6 ++                                        *A*                ###                     ++ 15
     |                                       **                 ##                         |
     |                                     **                ###                           |
     |                                  ***               ###                              |
     |                                **               ###                                 |
   5 ++                             **               ##                                    |
     |                           ***              ###                                     ++ 10
     |                         **              #B#                                         |
     |                       **            ####                                            |
   4 ++                   *A*           ###                                                |
     |                 ***          ####                                                   |
     |               **          ###                                                      ++ 5
     |            ***        ####                                                          |
   3 ++        ***      ###B#                                                              |
     |      *** ########                                                                   |
     |   #**####                                                                           |
     B#***      +          +         +          +          +          +         +          +
   2 A*---------+----------+---------+----------+----------+----------+---------+---------++ 0
     1         1.5         2        2.5         3         3.5         4        4.5         5
                                                x

EOF

tryplot( testname => 'lines on both axes with labels, legends, titles; different styles',
         cmd      => q{seq 5 | gawk '{print 2*$1, $1*$1}'},
         options  => ['--legend', '0', 'data 0',
                      '--title', "Test plot",
                      qw(--y2 1 --y2label y2 --xlabel x --ylabel y --y2max 30),
                      '--curvestyle', '0', 'with lines',
                      '--curvestyle', '1', 'with points ps 3 pt 7'],
         refplot  => <<'EOF' );

                                            Test plot
                                                                                              y2
  10 ++---------+----------+---------+----------+----------+----------+---------+---------** 30
     +          +          +         +          +          +          +      data 0 ****** +
     |                                                                               ***   |
     |                                                                            ***      |
   9 ++                                                                         **         |
     |                                                                       ***          +G 25
     |                                                                    ***              |
     |                                                                  **                 |
   8 ++                                                              ***                   |
     |                                                            ***                      |
     |                                                          **                         |
     |                                                       ***                          ++ 20
   7 ++                                                   ***                              |
     |                                                 ***                                 |
     |                                               **                                    |
     |                                            ***                 G                    |
   6 ++                                        ***                                        ++ 15
     |                                       **                                            |
     |                                     **                                              |
     |                                  ***                                                |
     |                                **                                                   |
   5 ++                             **                                                     |
     |                           ***                                                      ++ 10
     |                         **               G                                          |
     |                       **                                                            |
   4 ++                   ***                                                              |
     |                 ***                                                                 |
     |               **                                                                   ++ 5
     |            ***                                                                      |
   3 ++        ***         G                                                               |
     |      ***                                                                            |
     |    **                                                                               |
     G ***      +          +         +          +          +          +         +          +
   2 **---------+----------+---------+----------+----------+----------+---------+---------++ 0
     1         1.5         2        2.5         3         3.5         4        4.5         5
                                                x

EOF

tryplot( testname => 'domain plot',
         cmd      => q{seq 5 | gawk '{print 2*$1, $1*$1}'},
         options  => [qw(--lines --points), '--domain'],
         refplot  => <<'EOF' );


  25 ++---------+-----------+----------+-----------+----------+----------+-----------+---------+A
     +          +           +          +           +          +          +           +        **+
     |                                                                                      **  |
     |                                                                                    **    |
     |                                                                                   *      |
     |                                                                                 **       |
     |                                                                               **         |
  20 ++                                                                            **          ++
     |                                                                           **             |
     |                                                                          *               |
     |                                                                        **                |
     |                                                                      **                  |
     |                                                                    **                    |
     |                                                                  *A                      |
  15 ++                                                               **                       ++
     |                                                             ***                          |
     |                                                           **                             |
     |                                                        ***                               |
     |                                                      **                                  |
     |                                                    **                                    |
     |                                                 ***                                      |
  10 ++                                              **                                        ++
     |                                            *A*                                           |
     |                                         ***                                              |
     |                                     ****                                                 |
     |                                  ***                                                     |
     |                               ***                                                        |
     |                           ****                                                           |
   5 ++                       ***                                                              ++
     |                    **A*                                                                  |
     |                ****                                                                      |
     |           *****                                                                          |
     |      *****                                                                               |
     |  ****                                                                                    |
     A**        +           +          +           +          +          +           +          +
   0 ++---------+-----------+----------+-----------+----------+----------+-----------+---------++
     2          3           4          5           6          7          8           9          10

EOF

tryplot( testname => 'dataid plot',
         cmd      => q{seq 5 | gawk '{print 2*$1, $1*$1}'},
         options  => [qw(--lines --points),
                      qw(--dataid --autolegend)],
         refplot  => <<'EOF' );


  25 ++---------+-----------+----------+-----------+----------+----------+-----------+---------+E
     +          +           +          +           +          +          +           + 2 **A*** +
     |                                                                                 4 ##B### |
     |                                                                                 6 $$C$$$ |
     |                                                                                 8 %%D%%% |
     |                                                                                10 @@E@@@ |
     |                                                                                          |
  20 ++                                                                                        ++
     |                                                                                          |
     |                                                                                          |
     |                                                                                          |
     |                                                                                          |
     |                                                                                          |
     |                                                                   D                      |
  15 ++                                                                                        ++
     |                                                                                          |
     |                                                                                          |
     |                                                                                          |
     |                                                                                          |
     |                                                                                          |
     |                                                                                          |
  10 ++                                                                                        ++
     |                                             C                                            |
     |                                                                                          |
     |                                                                                          |
     |                                                                                          |
     |                                                                                          |
     |                                                                                          |
   5 ++                                                                                        ++
     |                      B                                                                   |
     |                                                                                          |
     |                                                                                          |
     |                                                                                          |
     |                                                                                          |
     A          +           +          +           +          +          +           +          +
   0 ++---------+-----------+----------+-----------+----------+----------+-----------+---------++
     1         1.5          2         2.5          3         3.5         4          4.5         5

EOF

tryplot( testname => '3d spiral with bounds, labels',
         cmd      => q{seq 50 | gawk '{print 2*cos($1/5), sin($1/5), $1}'},
         options  => [qw(--lines --points),
                      qw(--3d --domain --zmin -5 --zmax 45 --zlabel z),
                     '--extracmds', 'set view 60,30'],
         refplot  => <<'EOF' );







                                ***A****A****A****A***A**
                               *                         **A**
                                                              **A***A*
                                                                      *A*
                                                                         *A
                                                                           *
              +                                                             A
          40  |+               **A****A****A****A***A**                     A
              |             **A                        **A****A**          A
          30  |+         A*A                                     *A**    *A
              |         A                                            *AA*
       z  20  |+        AA**                                      **A*  *A*
              |             A**A***A***A****A*****A***A****A****A*         AA
          10  |+                        -+----                              A
              |                     ----     +---------                    A
           0  |+                 ---+             +    ---------
              |               ---++                          +-+---------
              |           ----++                                   +     ---------
              |        ---+                                                    + ----- 1
              |     ---+                                                      ---  0.8
              | ----+                                                      --++ 0.6
              +-+++---------                                           --- 0.20.4
           -2  -1.5 ++     +---------                               ---  0
                      -1  +     ++   --+------                   --- -0.2
                          -0.5     0 +     ++ ---------      ---+ -0.4
                                       0.5    1  ++   -+--- --0.8.6
                                                 1.5 +    +-1+
                                                         2





EOF

tryplot( testname => '3d spiral with bounds, labels, square xy aspect ratio',
         cmd      => q{seq 50 | gawk '{print 2*cos($1/5), sin($1/5), $1}'},
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

tryplot( testname => 'Monotonicity check',
         cmd      => q{seq 10 | gawk '{print (NR-1)%5,NR}'},
         options  => [qw(--lines --points --domain --monotonic)],
         refplot  => <<'EOF' );


   10 ++---------+-----------+----------+----------+----------+-----------+----------+---------*A
      +          +           +          +          +          +           +          +       ** +
      |                                                                                   ***   |
      |                                                                                 **      |
  9.5 ++                                                                             ***       ++
      |                                                                            **           |
      |                                                                          **             |
      |                                                                       ***               |
      |                                                                     **                  |
    9 ++                                                                 *A*                   ++
      |                                                               ***                       |
      |                                                            ***                          |
      |                                                         ***                             |
  8.5 ++                                                      **                               ++
      |                                                    ***                                  |
      |                                                 ***                                     |
      |                                              ***                                        |
    8 ++                                          *A*                                          ++
      |                                         **                                              |
      |                                      ***                                                |
      |                                    **                                                   |
      |                                 ***                                                     |
  7.5 ++                              **                                                       ++
      |                             **                                                          |
      |                          ***                                                            |
      |                        **                                                               |
    7 ++                    *A*                                                                ++
      |                   **                                                                    |
      |                ***                                                                      |
      |              **                                                                         |
      |           ***                                                                           |
  6.5 ++       ***                                                                             ++
      |      **                                                                                 |
      |   ***                                                                                   |
      + **       +           +          +          +          +           +          +          +
    6 A*---------+-----------+----------+----------+----------+-----------+----------+---------++
      0         0.5          1         1.5         2         2.5          3         3.5         4

EOF


tryplot( testname => 'basic --timefmt plot',
         cmd      => q{seq 5 | gawk '{print strftime("%d %b %Y %T",1382249107+$1,1),$1}'},
         options  => ['--domain', '--timefmt', '%d %b %Y %H:%M:%S'],
         refplot  => <<'EOF' );


    5 ++---------+-----------+----------+----------+----------+-----------+----------+---------+A
      +          +           +          +          +          +           +          +          +
      |                                                                                         |
      |                                                                                         |
  4.5 ++                                                                                       ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
    4 ++                                                                  A                    ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
  3.5 ++                                                                                       ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
    3 ++                                           A                                           ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
  2.5 ++                                                                                       ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
    2 ++                     A                                                                 ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
  1.5 ++                                                                                       ++
      |                                                                                         |
      |                                                                                         |
      +          +           +          +          +          +           +          +          +
    1 A+---------+-----------+----------+----------+----------+-----------+----------+---------++
    05:08      05:08       05:09      05:09      05:10      05:10       05:11      05:11      05:12

EOF

tryplot( testname => '--timefmt plot with bounds',
         cmd      => q{seq 5 | gawk '{print strftime("%d %b %Y %T",1382249107+$1,1),$1}'},
         options  => ['--domain', '--timefmt', '%d %b %Y %H:%M:%S',
                      '--xmin', '20 Oct 2013 06:05:00',
                      '--xmax', '20 Oct 2013 06:05:20'],
         refplot  => <<'EOF' );


    5 ++---+---+----+---+----+---+----+---+----+---+----+---A----+---+----+---+----+---+----+--++
      +                      +                     +                      +                     +
      |                                                                                         |
      |                                                                                         |
  4.5 ++                                                                                       ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
    4 ++                                                A                                      ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
  3.5 ++                                                                                       ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
    3 ++                                           A                                           ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
  2.5 ++                                                                                       ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
    2 ++                                       A                                               ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
  1.5 ++                                                                                       ++
      |                                                                                         |
      |                                                                                         |
      +                      +                     +                      +                     +
    1 ++---+---+----+---+----+---+----+---A----+---+----+---+----+---+----+---+----+---+----+--++
    05:00                  05:05                 05:10                  05:15                 05:20

EOF

tryplot( testname => '--timefmt plot with --monotonic',
         cmd      => q{seq 10 | gawk '{x=(NR-1)%5; print strftime("%d %b %Y %T",1382249107+x,1),$1}'},
         options  => ['--domain', '--timefmt', '%d %b %Y %H:%M:%S',
                      '--monotonic'],
         refplot  => <<'EOF' );


   10 ++---------+-----------+----------+----------+----------+-----------+----------+---------+A
      +          +           +          +          +          +           +          +          +
      |                                                                                         |
      |                                                                                         |
  9.5 ++                                                                                       ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
    9 ++                                                                  A                    ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
  8.5 ++                                                                                       ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
    8 ++                                           A                                           ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
  7.5 ++                                                                                       ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
    7 ++                     A                                                                 ++
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
      |                                                                                         |
  6.5 ++                                                                                       ++
      |                                                                                         |
      |                                                                                         |
      +          +           +          +          +          +           +          +          +
    6 A+---------+-----------+----------+----------+----------+-----------+----------+---------++
    05:07      05:07       05:08      05:08      05:09      05:09       05:10      05:10      05:11

EOF

tryplot( testname => 'Error bars (using extraValuesPerPoint)',
         cmd      => q{seq 5 | gawk '{print $1,$1,$1/10}'},
         options  => [qw(--domain),
                      qw(--extraValuesPerPoint 1 --curvestyle 0), 'with errorbars'],
         refplot  => <<'EOF' );


  5.5 ++---------+-----------+----------+----------+----------+-----------+----------+---------**
      +          +           +          +          +          +           +          +          *
      |                                                                                         *
    5 ++                                                                                       +A
      |                                                                                         *
      |                                                                                         *
      |                                                                                         *
  4.5 ++                                                                                       **
      |                                                                  ***                    |
      |                                                                   *                     |
    4 ++                                                                  A                    ++
      |                                                                   *                     |
      |                                                                   *                     |
      |                                                                  ***                    |
  3.5 ++                                                                                       ++
      |                                           ***                                           |
      |                                            *                                            |
    3 ++                                           A                                           ++
      |                                            *                                            |
      |                                            *                                            |
      |                                           ***                                           |
  2.5 ++                                                                                       ++
      |                                                                                         |
      |                     ***                                                                 |
    2 ++                     A                                                                 ++
      |                      *                                                                  |
      |                     ***                                                                 |
      |                                                                                         |
  1.5 ++                                                                                       ++
      |                                                                                         |
      |                                                                                         |
    1 A*                                                                                       ++
      **                                                                                        |
      |                                                                                         |
      +          +           +          +          +          +           +          +          +
  0.5 ++---------+-----------+----------+----------+----------+-----------+----------+---------++
      1         1.5          2         2.5         3         3.5          4         4.5         5

EOF


SKIP:
{

# Some tests aren't 100% reliable, so I do not include them in automated testing. These are
#
# - Histogram and circle-plotting tests: these have inconsistent round-off
#   behavior on different arches; specifically 32-bit and 64-bit x86. So both
#   plots look fine, but not identical, thus the tests fail
#
# - Streaming tests. These tests have a temporal component, so the loading of
#   the host machine can cause a test failure. It's fine pretty much all the
#   time on my not-too-new laptop, but this is bad for automated testing

skip "Skipping unreliable tests. Set RUN_ALL_TESTS environment variable to run them all", 18 unless $ENV{RUN_ALL_TESTS};


tryplot( testname => 'Histogram plot',
         cmd      => q{seq 50 | gawk '{print $1*$1}'},
         options  => [qw(--lines --points),
                      qw(--histo 0 --binwidth 50 --ymin 0 --curvestyleall), 'with boxes'],
         refplot  => <<'EOF' );


    4 ++----------****----------+------------+-----------+------------+------------+-----------++
      +           *+**          +            +           +            +            +            +
      |           * **                                                                          |
      |           * **                                                                          |
  3.5 ++          * **                                                                         ++
      |           * **                                                                          |
      |           * **                                                                          |
      |           * **                                                                          |
      |           * **                                                                          |
    3 ++          * ***                                                                        ++
      |           * ***                                                                         |
      |           * ***                                                                         |
      |           * ***                                                                         |
  2.5 ++          * ***                                                                        ++
      |           * ***                                                                         |
      |           * ***                                                                         |
      |           * ***                                                                         |
    2 ++          * **** ***                                                                   ++
      |           * **** ***                                                                    |
      |           * **** ***                                                                    |
      |           * **** ***                                                                    |
      |           * **** ***                                                                    |
  1.5 ++          * **** ***                                                                   ++
      |           * **** ***                                                                    |
      |           * **** ***                                                                    |
      |           * **** ***                                                                    |
    1 ++          * ************************** ******** ************************** **          ++
      |           * **** *** **** *** **** *** **** *** **** *** **** *** **** *** **           |
      |           * **** *** **** *** **** *** **** *** **** *** **** *** **** *** **           |
      |           * **** *** **** *** **** *** **** *** **** *** **** *** **** *** **           |
      |           * **** *** **** *** **** *** **** *** **** *** **** *** **** *** **           |
  0.5 ++          * **** *** **** *** **** *** **** *** **** *** **** *** **** *** **          ++
      |           * **** *** **** *** **** *** **** *** **** *** **** *** **** *** **           |
      |           * **** *** **** *** **** *** **** *** **** *** **** *** **** *** **           |
      +           *+**** *** **** *** **** *** **** *** **** *** **** *** **** *** **           +
    0 ++----------****************************-********-**************************-**----------++
    -500           0           500          1000        1500         2000         2500         3000

EOF

tryplot( testname => 'Cumulative histogram',
         cmd      => q{seq 50 | gawk '{print $1*$1}'},
         options  => [qw(--lines --points),
                      qw(--histo 0 --histstyle cum --binwidth 50 --ymin 0 --curvestyleall), 'with boxes'],
         refplot  => <<'EOF' );


  50 ++-----------+------------+------------+------------+------------+-----------***----------++
     +            +            +            +            +            +      ** ***+*           +
     |                                                                     **** *** *           |
     |                                                                 *** **** *** *           |
     |                                                              ** *** **** *** *           |
     |                                                           ***** *** **** *** *           |
     |                                                        **** *** *** **** *** *           |
  40 ++                                                    ** **** *** *** **** *** *          ++
     |                                                 ****** **** *** *** **** *** *           |
     |                                              ***** *** **** *** *** **** *** *           |
     |                                            *** *** *** **** *** *** **** *** *           |
     |                                         ****** *** *** **** *** *** **** *** *           |
     |                                        ** **** *** *** **** *** *** **** *** *           |
     |                                    ****** **** *** *** **** *** *** **** *** *           |
  30 ++                                  *** *** **** *** *** **** *** *** **** *** *          ++
     |                                ****** *** **** *** *** **** *** *** **** *** *           |
     |                               *** *** *** **** *** *** **** *** *** **** *** *           |
     |                            ****** *** *** **** *** *** **** *** *** **** *** *           |
     |                           ** **** *** *** **** *** *** **** *** *** **** *** *           |
     |                          *** **** *** *** **** *** *** **** *** *** **** *** *           |
     |                       ****** **** *** *** **** *** *** **** *** *** **** *** *           |
  20 ++                     *** *** **** *** *** **** *** *** **** *** *** **** *** *          ++
     |                   ****** *** **** *** *** **** *** *** **** *** *** **** *** *           |
     |                   ** *** *** **** *** *** **** *** *** **** *** *** **** *** *           |
     |                  *** *** *** **** *** *** **** *** *** **** *** *** **** *** *           |
     |                 **** *** *** **** *** *** **** *** *** **** *** *** **** *** *           |
     |               ****** *** *** **** *** *** **** *** *** **** *** *** **** *** *           |
     |              ** **** *** *** **** *** *** **** *** *** **** *** *** **** *** *           |
  10 ++             ** **** *** *** **** *** *** **** *** *** **** *** *** **** *** *          ++
     |             *** **** *** *** **** *** *** **** *** *** **** *** *** **** *** *           |
     |             *** **** *** *** **** *** *** **** *** *** **** *** *** **** *** *           |
     |             *** **** *** *** **** *** *** **** *** *** **** *** *** **** *** *           |
     |           ***** **** *** *** **** *** *** **** *** *** **** *** *** **** *** *           |
     |           * *** **** *** *** **** *** *** **** *** *** **** *** *** **** *** *           |
     +           *+*** **** ***+*** **** ***+*** **** ***+*** **** ***+*** **** ***+*           +
   0 ++----------********************************************-********+***-****-*****----------++
   -500           0           500          1000         1500         2000         2500         3000

EOF

tryplot( testname => 'Circles',
         cmd      => q{seq 5 | gawk '{print $1,$1,$1/10}'},
         options  => [qw(--circles --domain)],
         refplot  => <<'EOF' );


    5 ++-------+--------+--------+--------+--------+--------+--------+--------*******************
      +        +        +        +        +        +        +        +        *        +       *+
      |                                                              *        *                *|
      |                                                          ********     *                *|
  4.5 ++                                                        **      **    *                *+
      |                                                        **        **   **              **|
      |                                                       **          **   **            ** |
      |                                                       *            *    **          **  |
      |                                                       *            *     **        **   |
    4 ++                                                      *            **     **********   ++
      |                                                       *            *                    |
      |                                                       *            *                    |
      |                                            *          *            *                    |
  3.5 ++                                        ******        **          **                   ++
      |                                        *      *        **        **                     |
      |                                       *        *        **      **                      |
      |                                       *        *         ********                       |
    3 ++                                      *        **                                      ++
      |                                       *        *                                        |
      |                                       *        *                                        |
      |                                       *        *                                        |
      |                                        *      *                                         |
  2.5 ++                         *              ******                                         ++
      |                       ******                                                            |
      |                      **    **                                                           |
      |                      *      *                                                           |
    2 ++                     *      **                                                         ++
      |                      *      **                                                          |
      |                      *      *                                                           |
      |                      **    **                                                           |
      |                       ******                                                            |
  1.5 ++                                                                                       ++
      |                                                                                         |
      |        *                                                                                |
      +      ****       +        +        +        +        +        +        +        +        +
    1 ++-----*-+**------+--------+--------+--------+--------+--------+--------+--------+-------++
     0.5       1       1.5       2       2.5       3       3.5       4       4.5       5       5.5

EOF




note( "Starting to run streaming tests. These will take several seconds each" );

# replotting every 1.0 seconds. Data comes in every 1.1 seconds. Two data
# points, and then "exit", so I should have two frames worth of data plotted. I
# pre-send a 0 so that the gnuplot autoscaling is always well-defined
tryplot( testname => 'basic streaming test',
         cmd      => q{seq 500 | gawk 'BEGIN{ print 0; } {print (NR==3)? "exit" : $0; fflush(); system("sleep 1.2");}'},
         options  => [qw(--lines --points --stream)],
         refplot  => <<'EOF' );


    1 ++----------------+-----------------+-----------------+-----------------+----------------*A
      +                 +                 +                 +                 +              ** +
      |                                                                                   ***   |
      |                                                                                ***      |
      |                                                                              **         |
      |                                                                           ***           |
      |                                                                         **              |
  0.8 ++                                                                     ***               ++
      |                                                                    **                   |
      |                                                                 ***                     |
      |                                                              ***                        |
      |                                                            **                           |
      |                                                         ***                             |
      |                                                       **                                |
  0.6 ++                                                   ***                                 ++
      |                                                  **                                     |
      |                                               ***                                       |
      |                                            ***                                          |
      |                                          **                                             |
      |                                       ***                                               |
      |                                     **                                                  |
  0.4 ++                                 ***                                                   ++
      |                                **                                                       |
      |                             ***                                                         |
      |                          ***                                                            |
      |                        **                                                               |
      |                     ***                                                                 |
      |                   **                                                                    |
  0.2 ++               ***                                                                     ++
      |              **                                                                         |
      |           ***                                                                           |
      |        ***                                                                              |
      |      **                                                                                 |
      |   ***                                                                                   |
      + **              +                 +                 +                 +                 +
    0 A*----------------+-----------------+-----------------+-----------------+----------------++
      1                1.2               1.4               1.6               1.8                2



    2 ++---------------------+---------------------+----------------------+--------------------*A
      +                      +                     +                      +                  ** +
      |                                                                                   ***   |
      |                                                                                ***      |
      |                                                                              **         |
      |                                                                           ***           |
      |                                                                        ***              |
      |                                                                      **                 |
      |                                                                   ***                   |
  1.5 ++                                                               ***                     ++
      |                                                              **                         |
      |                                                           ***                           |
      |                                                        ***                              |
      |                                                      **                                 |
      |                                                   ***                                   |
      |                                                ***                                      |
      |                                              **                                         |
    1 ++                                          *A*                                          ++
      |                                         **                                              |
      |                                      ***                                                |
      |                                    **                                                   |
      |                                 ***                                                     |
      |                               **                                                        |
      |                            ***                                                          |
      |                          **                                                             |
      |                       ***                                                               |
  0.5 ++                    **                                                                 ++
      |                  ***                                                                    |
      |                **                                                                       |
      |             ***                                                                         |
      |           **                                                                            |
      |        ***                                                                              |
      |      **                                                                                 |
      |   ***                                                                                   |
      + **                   +                     +                      +                     +
    0 A*---------------------+---------------------+----------------------+--------------------++
      1                     1.5                    2                     2.5                    3

EOF

tryplot( testname => 'basic streaming test, twice as fast',
         cmd      => q{seq 500 | gawk 'BEGIN{ print 0; } {print (NR==3)? "exit" : $0; fflush(); system("sleep 0.6");}'},
         options  => [qw(--lines --points --stream 0.4)],
         refplot  => <<'EOF' );


    1 ++----------------+-----------------+-----------------+-----------------+----------------*A
      +                 +                 +                 +                 +              ** +
      |                                                                                   ***   |
      |                                                                                ***      |
      |                                                                              **         |
      |                                                                           ***           |
      |                                                                         **              |
  0.8 ++                                                                     ***               ++
      |                                                                    **                   |
      |                                                                 ***                     |
      |                                                              ***                        |
      |                                                            **                           |
      |                                                         ***                             |
      |                                                       **                                |
  0.6 ++                                                   ***                                 ++
      |                                                  **                                     |
      |                                               ***                                       |
      |                                            ***                                          |
      |                                          **                                             |
      |                                       ***                                               |
      |                                     **                                                  |
  0.4 ++                                 ***                                                   ++
      |                                **                                                       |
      |                             ***                                                         |
      |                          ***                                                            |
      |                        **                                                               |
      |                     ***                                                                 |
      |                   **                                                                    |
  0.2 ++               ***                                                                     ++
      |              **                                                                         |
      |           ***                                                                           |
      |        ***                                                                              |
      |      **                                                                                 |
      |   ***                                                                                   |
      + **              +                 +                 +                 +                 +
    0 A*----------------+-----------------+-----------------+-----------------+----------------++
      1                1.2               1.4               1.6               1.8                2



    2 ++---------------------+---------------------+----------------------+--------------------*A
      +                      +                     +                      +                  ** +
      |                                                                                   ***   |
      |                                                                                ***      |
      |                                                                              **         |
      |                                                                           ***           |
      |                                                                        ***              |
      |                                                                      **                 |
      |                                                                   ***                   |
  1.5 ++                                                               ***                     ++
      |                                                              **                         |
      |                                                           ***                           |
      |                                                        ***                              |
      |                                                      **                                 |
      |                                                   ***                                   |
      |                                                ***                                      |
      |                                              **                                         |
    1 ++                                          *A*                                          ++
      |                                         **                                              |
      |                                      ***                                                |
      |                                    **                                                   |
      |                                 ***                                                     |
      |                               **                                                        |
      |                            ***                                                          |
      |                          **                                                             |
      |                       ***                                                               |
  0.5 ++                    **                                                                 ++
      |                  ***                                                                    |
      |                **                                                                       |
      |             ***                                                                         |
      |           **                                                                            |
      |        ***                                                                              |
      |      **                                                                                 |
      |   ***                                                                                   |
      + **                   +                     +                      +                     +
    0 A*---------------------+---------------------+----------------------+--------------------++
      1                     1.5                    2                     2.5                    3

EOF


tryplot( testname => 'streaming with --xlen',
         cmd      => q{seq 500 | gawk 'BEGIN{ print 0; } {print (NR==3)? "exit" : $0; fflush(); system("sleep 0.6");}'},
         options  => [qw(--lines --points --stream 0.4 --xlen 1.1)],
         refplot  => <<'EOF' );


    1 ++------+----------------+---------------+---------------+----------------+--------------*A
      |       +                +               +               +                +            ** +
      |                                                                                    **   |
      |                                                                                 ***     |
      |                                                                               **        |
      |                                                                             **          |
      |                                                                          ***            |
  0.8 ++                                                                       **              ++
      |                                                                      **                 |
      |                                                                   ***                   |
      |                                                                 **                      |
      |                                                               **                        |
      |                                                            ***                          |
      |                                                          **                             |
  0.6 ++                                                       **                              ++
      |                                                     ***                                 |
      |                                                   **                                    |
      |                                                ***                                      |
      |                                              **                                         |
      |                                            **                                           |
      |                                         ***                                             |
  0.4 ++                                      **                                               ++
      |                                     **                                                  |
      |                                  ***                                                    |
      |                                **                                                       |
      |                              **                                                         |
      |                           ***                                                           |
      |                         **                                                              |
  0.2 ++                      **                                                               ++
      |                    ***                                                                  |
      |                  **                                                                     |
      |                **                                                                       |
      |             ***                                                                         |
      |           **                                                                            |
      |       + **             +               +               +                +               +
    0 ++------A*---------------+---------------+---------------+----------------+--------------++
              1               1.2             1.4             1.6              1.8              2



    2 ++------+----------------+---------------+---------------+----------------+--------------*A
      |       +                +               +               +                +            ** +
      |                                                                                    **   |
      |                                                                                 ***     |
      |                                                                               **        |
      |                                                                             **          |
      |                                                                          ***            |
  1.8 ++                                                                       **              ++
      |                                                                      **                 |
      |                                                                   ***                   |
      |                                                                 **                      |
      |                                                               **                        |
      |                                                            ***                          |
      |                                                          **                             |
  1.6 ++                                                       **                              ++
      |                                                     ***                                 |
      |                                                   **                                    |
      |                                                ***                                      |
      |                                              **                                         |
      |                                            **                                           |
      |                                         ***                                             |
  1.4 ++                                      **                                               ++
      |                                     **                                                  |
      |                                  ***                                                    |
      |                                **                                                       |
      |                              **                                                         |
      |                           ***                                                           |
      |                         **                                                              |
  1.2 ++                      **                                                               ++
      |                    ***                                                                  |
      |                  **                                                                     |
      |                **                                                                       |
      |             ***                                                                         |
      |           **                                                                            |
      |       + **             +               +               +                +               +
    1 ++------A*---------------+---------------+---------------+----------------+--------------++
              2               2.2             2.4             2.6              2.8              3

EOF

tryplot( testname => 'streaming with --monotonic',
         cmd      => q{seq 500 | gawk '{if(NR==11) {print "exit";} else {x=(NR-1)%5; if(x==0) {print -1,-1;} print x,NR;}; fflush(); system("sleep 0.6");}'},
         options  => [qw(--lines --points --stream 0.4 --domain --monotonic)],
         refplot  => <<'EOF' );


    1 ++----------------+-----------------+-----------------+-----------------+----------------*A
      +                 +                 +                 +                 +              ** +
      |                                                                                   ***   |
      |                                                                                ***      |
      |                                                                              **         |
      |                                                                           ***           |
      |                                                                         **              |
      |                                                                      ***                |
      |                                                                    **                   |
  0.5 ++                                                                ***                    ++
      |                                                              ***                        |
      |                                                            **                           |
      |                                                         ***                             |
      |                                                       **                                |
      |                                                    ***                                  |
      |                                                  **                                     |
      |                                               ***                                       |
    0 ++                                           ***                                         ++
      |                                          **                                             |
      |                                       ***                                               |
      |                                     **                                                  |
      |                                  ***                                                    |
      |                                **                                                       |
      |                             ***                                                         |
      |                          ***                                                            |
      |                        **                                                               |
 -0.5 ++                    ***                                                                ++
      |                   **                                                                    |
      |                ***                                                                      |
      |              **                                                                         |
      |           ***                                                                           |
      |        ***                                                                              |
      |      **                                                                                 |
      |   ***                                                                                   |
      + **              +                 +                 +                 +                 +
   -1 A*----------------+-----------------+-----------------+-----------------+----------------++
     -1               -0.8              -0.6              -0.4              -0.2                0



    2 ++---------------------+---------------------+----------------------+--------------------*A
      +                      +                     +                      +                **** +
      |                                                                                ****     |
      |                                                                            ****         |
      |                                                                         ***             |
      |                                                                     ****                |
  1.5 ++                                                                ****                   ++
      |                                                             ****                        |
      |                                                          ***                            |
      |                                                      ****                               |
      |                                                  ****                                   |
      |                                              ****                                       |
    1 ++                                           A*                                          ++
      |                                          **                                             |
      |                                        **                                               |
      |                                      **                                                 |
      |                                    **                                                   |
  0.5 ++                                 **                                                    ++
      |                                **                                                       |
      |                              **                                                         |
      |                            **                                                           |
      |                          **                                                             |
      |                        **                                                               |
    0 ++                     **                                                                ++
      |                    **                                                                   |
      |                  **                                                                     |
      |                **                                                                       |
      |              **                                                                         |
      |            **                                                                           |
 -0.5 ++         **                                                                            ++
      |        **                                                                               |
      |      **                                                                                 |
      |    **                                                                                   |
      |  **                                                                                     |
      +**                    +                     +                      +                     +
   -1 A+---------------------+---------------------+----------------------+--------------------++
     -1                    -0.5                    0                     0.5                    1



    3 ++-------------+--------------+--------------+--------------+--------------+-------------*A
      +              +              +              +              +              +         **** +
      |                                                                                 ***     |
      |                                                                              ***        |
  2.5 ++                                                                         ****          ++
      |                                                                       ***               |
      |                                                                    ***                  |
      |                                                                ****                     |
      |                                                             ***                         |
    2 ++                                                         *A*                           ++
      |                                                      ****                               |
      |                                                  ****                                   |
      |                                              ****                                       |
  1.5 ++                                          ***                                          ++
      |                                       ****                                              |
      |                                   ****                                                  |
      |                               ****                                                      |
    1 ++                            A*                                                         ++
      |                           **                                                            |
      |                         **                                                              |
      |                        *                                                                |
      |                      **                                                                 |
  0.5 ++                   **                                                                  ++
      |                   *                                                                     |
      |                 **                                                                      |
      |               **                                                                        |
    0 ++             *                                                                         ++
      |            **                                                                           |
      |          **                                                                             |
      |         *                                                                               |
      |       **                                                                                |
 -0.5 ++    **                                                                                 ++
      |    *                                                                                    |
      |  **                                                                                     |
      +**            +              +              +              +              +              +
   -1 A+-------------+--------------+--------------+--------------+--------------+-------------++
     -1            -0.5             0             0.5             1             1.5             2



  4 ++----------+----------+-----------+----------+-----------+----------+-----------+---------*A
    +           +          +           +          +           +          +           +      *** +
    |                                                                                   ****    |
    |                                                                                ***        |
    |                                                                             ***           |
    |                                                                         ****              |
    |                                                                      ***                  |
  3 ++                                                                  *A*                    ++
    |                                                                ***                        |
    |                                                            ****                           |
    |                                                         ***                               |
    |                                                      ***                                  |
    |                                                  ****                                     |
    |                                               ***                                         |
  2 ++                                           *A*                                           ++
    |                                         ***                                               |
    |                                     ****                                                  |
    |                                  ***                                                      |
    |                               ***                                                         |
    |                           ****                                                            |
    |                        ***                                                                |
  1 ++                     A*                                                                  ++
    |                    **                                                                     |
    |                  **                                                                       |
    |                 *                                                                         |
    |               **                                                                          |
    |             **                                                                            |
    |            *                                                                              |
  0 ++         **                                                                              ++
    |         *                                                                                 |
    |       **                                                                                  |
    |     **                                                                                    |
    |    *                                                                                      |
    |  **                                                                                       |
    +**         +          +           +          +           +          +           +          +
 -1 A+----------+----------+-----------+----------+-----------+----------+-----------+---------++
   -1         -0.5         0          0.5         1          1.5         2          2.5         3



  5 ++----------------+------------------+-----------------+------------------+----------------*A
    +                 +                  +                 +                  +             *** +
    |                                                                                    ***    |
    |                                                                                 ***       |
    |                                                                              ***          |
    |                                                                           ***             |
  4 ++                                                                       *A*               ++
    |                                                                     ***                   |
    |                                                                  ***                      |
    |                                                              ****                         |
    |                                                           ***                             |
    |                                                        ***                                |
  3 ++                                                    *A*                                  ++
    |                                                 ****                                      |
    |                                             ****                                          |
    |                                          ***                                              |
    |                                      ****                                                 |
  2 ++                                  *A*                                                    ++
    |                                ***                                                        |
    |                             ***                                                           |
    |                         ****                                                              |
    |                      ***                                                                  |
    |                   ***                                                                     |
  1 ++                A*                                                                       ++
    |               **                                                                          |
    |              *                                                                            |
    |            **                                                                             |
    |           *                                                                               |
    |         **                                                                                |
  0 ++       *                                                                                 ++
    |      **                                                                                   |
    |     *                                                                                     |
    |   **                                                                                      |
    |  *                                                                                        |
    +**               +                  +                 +                  +                 +
 -1 A+----------------+------------------+-----------------+------------------+----------------++
   -1                 0                  1                 2                  3                 4



  6 ++----------------+------------------+-----------------+------------------+----------------*A
    +                 +                  +                 +                  +              ** +
    |                                                                                     ***   |
    |                                                                                  ***      |
    |                                                                                **         |
  5 ++                                                                            ***          ++
    |                                                                          ***              |
    |                                                                        **                 |
    |                                                                     ***                   |
    |                                                                   **                      |
  4 ++                                                               ***                       ++
    |                                                             ***                           |
    |                                                           **                              |
    |                                                        ***                                |
    |                                                     ***                                   |
  3 ++                                                  **                                     ++
    |                                                ***                                        |
    |                                             ***                                           |
    |                                           **                                              |
    |                                        ***                                                |
  2 ++                                     **                                                  ++
    |                                   ***                                                     |
    |                                ***                                                        |
    |                              **                                                           |
    |                           ***                                                             |
  1 ++                       ***                                                               ++
    |                      **                                                                   |
    |                   ***                                                                     |
    |                 **                                                                        |
    |              ***                                                                          |
  0 ++          ***                                                                            ++
    |         **                                                                                |
    |      ***                                                                                  |
    |   ***                                                                                     |
    + **              +                  +                 +                  +                 +
 -1 A*----------------+------------------+-----------------+------------------+----------------++
   -1               -0.8               -0.6              -0.4               -0.2                0



  7 ++---------------------+----------------------+----------------------+-----------------*****A
    +                      +                      +                      +     ************     +
    |                                                               ***********                 |
    |                                                   ************                            |
  6 ++                                            A*****                                       ++
    |                                           **                                              |
    |                                          *                                                |
    |                                        **                                                 |
    |                                       *                                                   |
  5 ++                                    **                                                   ++
    |                                    *                                                      |
    |                                  **                                                       |
    |                                 *                                                         |
  4 ++                              **                                                         ++
    |                              *                                                            |
    |                            **                                                             |
    |                           *                                                               |
  3 ++                        **                                                               ++
    |                        *                                                                  |
    |                      **                                                                   |
    |                     *                                                                     |
    |                    *                                                                      |
  2 ++                 **                                                                      ++
    |                 *                                                                         |
    |               **                                                                          |
    |              *                                                                            |
  1 ++           **                                                                            ++
    |           *                                                                               |
    |         **                                                                                |
    |        *                                                                                  |
    |      **                                                                                   |
  0 ++    *                                                                                    ++
    |   **                                                                                      |
    |  *                                                                                        |
    +**                    +                      +                      +                      +
 -1 A+---------------------+----------------------+----------------------+---------------------++
   -1                    -0.5                     0                     0.5                     1



  8 ++-------------+---------------+--------------+--------------+---------------+-----------***A
    +              +               +              +              +               +   ********   +
    |                                                                        ********           |
    |                                                                ********                   |
  7 ++                                                        ***A***                          ++
    |                                                 ********                                  |
    |                                          *******                                          |
    |                                  ********                                                 |
  6 ++                             A***                                                        ++
    |                             *                                                             |
    |                            *                                                              |
    |                          **                                                               |
  5 ++                        *                                                                ++
    |                        *                                                                  |
    |                       *                                                                   |
    |                      *                                                                    |
  4 ++                    *                                                                    ++
    |                    *                                                                      |
    |                  **                                                                       |
  3 ++                *                                                                        ++
    |                *                                                                          |
    |               *                                                                           |
    |              *                                                                            |
  2 ++            *                                                                            ++
    |            *                                                                              |
    |          **                                                                               |
    |         *                                                                                 |
  1 ++       *                                                                                 ++
    |       *                                                                                   |
    |      *                                                                                    |
    |     *                                                                                     |
  0 ++   *                                                                                     ++
    |  **                                                                                       |
    | *                                                                                         |
    +*             +               +              +              +               +              +
 -1 A+-------------+---------------+--------------+--------------+---------------+-------------++
   -1            -0.5              0             0.5             1              1.5             2



  10 ++---------+-----------+----------+-----------+----------+----------+-----------+---------++
     +          +           +          +           +          +          +           +          +
     |                                                                                          |
     |                                                                                       ***A
     |                                                                               ********   |
     |                                                                       ********           |
   8 ++                                                               ***A***                  ++
     |                                                        ********                          |
     |                                                 *******                                  |
     |                                          ***A***                                         |
     |                                  ********                                                |
     |                          ********                                                        |
   6 ++                     A***                                                               ++
     |                     *                                                                    |
     |                    *                                                                     |
     |                  **                                                                      |
     |                 *                                                                        |
   4 ++               *                                                                        ++
     |               *                                                                          |
     |              *                                                                           |
     |             *                                                                            |
     |            *                                                                             |
     |          **                                                                              |
   2 ++        *                                                                               ++
     |        *                                                                                 |
     |       *                                                                                  |
     |      *                                                                                   |
     |     *                                                                                    |
     |    *                                                                                     |
   0 ++ **                                                                                     ++
     | *                                                                                        |
     |*                                                                                         |
     A                                                                                          |
     |                                                                                          |
     +          +           +          +           +          +          +           +          +
  -2 ++---------+-----------+----------+-----------+----------+----------+-----------+---------++
    -1        -0.5          0         0.5          1         1.5         2          2.5         3



  10 ++----------------+-----------------+------------------+-----------------+--------------***A
     +                 +                 +                  +                 +        ******   +
     |                                                                           ******         |
     |                                                                     ***A**               |
     |                                                               ******                     |
     |                                                         ******                           |
   8 ++                                                  ***A**                                ++
     |                                             ******                                       |
     |                                       ******                                             |
     |                                ***A***                                                   |
     |                          ******                                                          |
     |                    ******                                                                |
   6 ++                A**                                                                     ++
     |                *                                                                         |
     |               *                                                                          |
     |              *                                                                           |
     |             *                                                                            |
   4 ++            *                                                                           ++
     |            *                                                                             |
     |           *                                                                              |
     |          *                                                                               |
     |         *                                                                                |
     |        *                                                                                 |
   2 ++      *                                                                                 ++
     |      *                                                                                   |
     |     *                                                                                    |
     |    *                                                                                     |
     |    *                                                                                     |
     |   *                                                                                      |
   0 ++ *                                                                                      ++
     | *                                                                                        |
     |*                                                                                         |
     A                                                                                          |
     |                                                                                          |
     +                 +                 +                  +                 +                 +
  -2 ++----------------+-----------------+------------------+-----------------+----------------++
    -1                 0                 1                  2                 3                 4

EOF

tryplot( testname => '--timefmt streaming plot with --xlen',
         cmd      => q{seq 5 | gawk 'BEGIN{ print strftime("%d %b %Y %T",1382249107-1,1),-4;} {if(NR==3) {print "exit";} else{ print strftime("%d %b %Y %T",1382249107+$1,1),$1;} fflush(); system("sleep 0.6")}'},
         options  => ['--points', '--lines',
                      '--domain', '--timefmt', '%d %b %Y %H:%M:%S',
                      qw(--stream 0.4 --xlen 3)],
         refplot  => <<'EOF' );


  1 ++-------------+---------------+--------------+--------------+---------------+-------------+A
    +              +               +              +              +               +            **+
    |                                                                                       **  |
    |                                                                                     **    |
    |                                                                                    *      |
    |                                                                                  **       |
    |                                                                                **         |
  0 ++                                                                             **          ++
    |                                                                             *             |
    |                                                                           **              |
    |                                                                         **                |
    |                                                                       **                  |
    |                                                                      *                    |
    |                                                                    **                     |
 -1 ++                                                                 **                      ++
    |                                                                **                         |
    |                                                               *                           |
    |                                                             **                            |
    |                                                           **                              |
    |                                                          *                                |
    |                                                        **                                 |
 -2 ++                                                     **                                  ++
    |                                                    **                                     |
    |                                                   *                                       |
    |                                                 **                                        |
    |                                               **                                          |
    |                                             **                                            |
    |                                            *                                              |
 -3 ++                                         **                                              ++
    |                                        **                                                 |
    |                                      **                                                   |
    |                                     *                                                     |
    |                                   **                                                      |
    |                                 **                                                        |
    +              +               +**            +              +               +              +
 -4 ++-------------+---------------A--------------+--------------+---------------+-------------++
  05:05          05:05           05:06          05:06          05:07           05:07          05:08



  2 ++-------------+---------------+--------------+--------------+---------------+------------**A
    +              +               +              +              +               +       *****  +
    |                                                                               *****       |
    |                                                                         ******            |
    |                                                                    *****                  |
    |                                                               *****                       |
  1 ++                                                          *A**                           ++
    |                                                         **                                |
    |                                                       **                                  |
    |                                                     **                                    |
    |                                                   **                                      |
    |                                                 **                                        |
  0 ++                                              **                                         ++
    |                                             **                                            |
    |                                           **                                              |
    |                                         **                                                |
    |                                      ***                                                  |
 -1 ++                                   **                                                    ++
    |                                  **                                                       |
    |                                **                                                         |
    |                              **                                                           |
    |                            **                                                             |
    |                          **                                                               |
 -2 ++                       **                                                                ++
    |                      **                                                                   |
    |                   ***                                                                     |
    |                 **                                                                        |
    |               **                                                                          |
    |             **                                                                            |
 -3 ++          **                                                                             ++
    |         **                                                                                |
    |       **                                                                                  |
    |     **                                                                                    |
    |   **                                                                                      |
    + **           +               +              +              +               +              +
 -4 A*-------------+---------------+--------------+--------------+---------------+-------------++
  05:06          05:06           05:07          05:07          05:08           05:08          05:09

EOF

tryplot( testname => '--timefmt streaming plot with --monotonic',
         cmd      => q{seq 10 | gawk '{x=(NR-1)%5; if(x==0) {print strftime("%d %b %Y %T",1382249107-1,-4),-4;} print strftime("%d %b %Y %T",1382249107+x,1),NR; fflush(); system("sleep 0.6")}'},
         options  => ['--points', '--lines',
                      '--domain', '--timefmt', '%d %b %Y %H:%M:%S',
                      qw(--stream 0.4 --monotonic)],
         refplot  => <<'EOF' );


  1 ++----------------+------------------+-----------------+------------------+----------------*A
    +                 +                  +                 +                  +              ** +
    |                                                                                     ***   |
    |                                                                                  ***      |
    |                                                                                **         |
    |                                                                             ***           |
    |                                                                          ***              |
  0 ++                                                                       **                ++
    |                                                                     ***                   |
    |                                                                   **                      |
    |                                                                ***                        |
    |                                                             ***                           |
    |                                                           **                              |
    |                                                        ***                                |
 -1 ++                                                    ***                                  ++
    |                                                   **                                      |
    |                                                ***                                        |
    |                                             ***                                           |
    |                                           **                                              |
    |                                        ***                                                |
    |                                      **                                                   |
 -2 ++                                  ***                                                    ++
    |                                ***                                                        |
    |                              **                                                           |
    |                           ***                                                             |
    |                        ***                                                                |
    |                      **                                                                   |
    |                   ***                                                                     |
 -3 ++                **                                                                       ++
    |              ***                                                                          |
    |           ***                                                                             |
    |         **                                                                                |
    |      ***                                                                                  |
    |   ***                                                                                     |
    + **              +                  +                 +                  +                 +
 -4 A*----------------+------------------+-----------------+------------------+----------------++
  05:06             05:06              05:06             05:06              05:06             05:06



  2 ++---------------------+----------------------+----------------------+-------------------***A
    +                      +                      +                      +           ********   +
    |                                                                        ********           |
    |                                                                 *******                   |
    |                                                         ********                          |
    |                                                 ********                                  |
  1 ++                                            A***                                         ++
    |                                           **                                              |
    |                                          *                                                |
    |                                        **                                                 |
    |                                      **                                                   |
    |                                     *                                                     |
  0 ++                                  **                                                     ++
    |                                  *                                                        |
    |                                **                                                         |
    |                              **                                                           |
    |                             *                                                             |
 -1 ++                          **                                                             ++
    |                          *                                                                |
    |                        **                                                                 |
    |                      **                                                                   |
    |                     *                                                                     |
    |                   **                                                                      |
 -2 ++                 *                                                                       ++
    |                **                                                                         |
    |               *                                                                           |
    |             **                                                                            |
    |           **                                                                              |
    |          *                                                                                |
 -3 ++       **                                                                                ++
    |       *                                                                                   |
    |     **                                                                                    |
    |   **                                                                                      |
    |  *                                                                                        |
    +**                    +                      +                      +                      +
 -4 A+---------------------+----------------------+----------------------+---------------------++
  05:06                  05:06                  05:07                  05:07                  05:08



  3 ++-------------+---------------+--------------+--------------+---------------+-----------***A
    +              +               +              +              +               +     ******   +
    |                                                                            ******         |
    |                                                                      ******               |
    |                                                                ******                     |
  2 ++                                                        ***A***                          ++
    |                                                   ******                                  |
    |                                             ******                                        |
    |                                       ******                                              |
    |                                 ******                                                    |
  1 ++                             A**                                                         ++
    |                             *                                                             |
    |                           **                                                              |
    |                          *                                                                |
    |                         *                                                                 |
  0 ++                       *                                                                 ++
    |                      **                                                                   |
    |                     *                                                                     |
    |                    *                                                                      |
    |                   *                                                                       |
 -1 ++                **                                                                       ++
    |                *                                                                          |
    |               *                                                                           |
    |              *                                                                            |
    |             *                                                                             |
 -2 ++          **                                                                             ++
    |          *                                                                                |
    |         *                                                                                 |
    |        *                                                                                  |
    |      **                                                                                   |
 -3 ++    *                                                                                    ++
    |    *                                                                                      |
    |   *                                                                                       |
    | **                                                                                        |
    +*             +               +              +              +               +              +
 -4 A+-------------+---------------+--------------+--------------+---------------+-------------++
  05:06          05:06           05:07          05:07          05:08           05:08          05:09



  4 ++----------+----------+-----------+----------+-----------+----------+-----------+--------**A
    +           +          +           +          +           +          +           +  ******  +
    |                                                                             ******        |
    |                                                                       ******              |
  3 ++                                                                 **A**                   ++
    |                                                              ****                         |
    |                                                         *****                             |
    |                                                    *****                                  |
    |                                                ****                                       |
  2 ++                                          **A**                                          ++
    |                                     ******                                                |
    |                               ******                                                      |
    |                         ******                                                            |
  1 ++                     A**                                                                 ++
    |                     *                                                                     |
    |                    *                                                                      |
    |                   *                                                                       |
  0 ++                 *                                                                       ++
    |                 *                                                                         |
    |                *                                                                          |
    |               *                                                                           |
    |              *                                                                            |
 -1 ++            *                                                                            ++
    |            *                                                                              |
    |          **                                                                               |
    |         *                                                                                 |
 -2 ++       *                                                                                 ++
    |       *                                                                                   |
    |      *                                                                                    |
    |     *                                                                                     |
    |    *                                                                                      |
 -3 ++  *                                                                                      ++
    |  *                                                                                        |
    | *                                                                                         |
    +*          +          +           +          +           +          +           +          +
 -4 A+----------+----------+-----------+----------+-----------+----------+-----------+---------++
  05:06       05:06      05:07       05:07      05:08       05:08      05:09       05:09      05:10



  5 ++----------------+------------------+-----------------+------------------+---------------**A
    +                 +                  +                 +                  +           ****  +
    |                                                                                *****      |
    |                                                                            ****           |
  4 ++                                                                      **A**              ++
    |                                                                  *****                    |
    |                                                              ****                         |
    |                                                         *****                             |
  3 ++                                                   **A**                                 ++
    |                                                ****                                       |
    |                                           *****                                           |
    |                                       ****                                                |
  2 ++                                 **A**                                                   ++
    |                             *****                                                         |
    |                         ****                                                              |
    |                    *****                                                                  |
  1 ++                A**                                                                      ++
    |                *                                                                          |
    |               *                                                                           |
  0 ++             *                                                                           ++
    |             *                                                                             |
    |            *                                                                              |
    |           *                                                                               |
 -1 ++         *                                                                               ++
    |         *                                                                                 |
    |        *                                                                                  |
    |        *                                                                                  |
 -2 ++      *                                                                                  ++
    |      *                                                                                    |
    |     *                                                                                     |
    |    *                                                                                      |
 -3 ++  *                                                                                      ++
    |  *                                                                                        |
    | *                                                                                         |
    +*                +                  +                 +                  +                 +
 -4 A+----------------+------------------+-----------------+------------------+----------------++
  05:06             05:07              05:08             05:09              05:10             05:11



  6 ++----------------+------------------+-----------------+------------------+----------------*A
    +                 +                  +                 +                  +              ** +
    |                                                                                     ***   |
    |                                                                                  ***      |
    |                                                                                **         |
    |                                                                             ***           |
    |                                                                          ***              |
  4 ++                                                                       **                ++
    |                                                                     ***                   |
    |                                                                   **                      |
    |                                                                ***                        |
    |                                                             ***                           |
    |                                                           **                              |
    |                                                        ***                                |
  2 ++                                                    ***                                  ++
    |                                                   **                                      |
    |                                                ***                                        |
    |                                             ***                                           |
    |                                           **                                              |
    |                                        ***                                                |
    |                                      **                                                   |
  0 ++                                  ***                                                    ++
    |                                ***                                                        |
    |                              **                                                           |
    |                           ***                                                             |
    |                        ***                                                                |
    |                      **                                                                   |
    |                   ***                                                                     |
 -2 ++                **                                                                       ++
    |              ***                                                                          |
    |           ***                                                                             |
    |         **                                                                                |
    |      ***                                                                                  |
    |   ***                                                                                     |
    + **              +                  +                 +                  +                 +
 -4 A*----------------+------------------+-----------------+------------------+----------------++
  05:06             05:06              05:06             05:06              05:06             05:06



  8 ++---------------------+----------------------+----------------------+---------------------++
    +                      +                      +                      +                      +
    |                                                                                           |
    |                                                                                    *******A
    |                                                                    ****************       |
    |                                                     ***************                       |
  6 ++                                            A*******                                     ++
    |                                           **                                              |
    |                                          *                                                |
    |                                        **                                                 |
    |                                      **                                                   |
    |                                     *                                                     |
  4 ++                                  **                                                     ++
    |                                  *                                                        |
    |                                **                                                         |
    |                              **                                                           |
    |                             *                                                             |
  2 ++                          **                                                             ++
    |                          *                                                                |
    |                        **                                                                 |
    |                      **                                                                   |
    |                     *                                                                     |
    |                   **                                                                      |
  0 ++                 *                                                                       ++
    |                **                                                                         |
    |               *                                                                           |
    |             **                                                                            |
    |           **                                                                              |
    |          *                                                                                |
 -2 ++       **                                                                                ++
    |       *                                                                                   |
    |     **                                                                                    |
    |   **                                                                                      |
    |  *                                                                                        |
    +**                    +                      +                      +                      +
 -4 A+---------------------+----------------------+----------------------+---------------------++
  05:06                  05:06                  05:07                  05:07                  05:08



  8 ++-------------+---------------+--------------+--------------+---------------+---------*****A
    +              +               +              +              +               **********     +
    |                                                                  **********               |
    |                                                       *****A*****                         |
    |                                             **********                                    |
    |                                   **********                                              |
  6 ++                             A****                                                       ++
    |                             *                                                             |
    |                            *                                                              |
    |                           *                                                               |
    |                          *                                                                |
    |                         *                                                                 |
  4 ++                       *                                                                 ++
    |                      **                                                                   |
    |                     *                                                                     |
    |                    *                                                                      |
    |                   *                                                                       |
  2 ++                 *                                                                       ++
    |                 *                                                                         |
    |                *                                                                          |
    |               *                                                                           |
    |              *                                                                            |
    |             *                                                                             |
  0 ++           *                                                                             ++
    |           *                                                                               |
    |          *                                                                                |
    |         *                                                                                 |
    |        *                                                                                  |
    |      **                                                                                   |
 -2 ++    *                                                                                    ++
    |    *                                                                                      |
    |   *                                                                                       |
    |  *                                                                                        |
    | *                                                                                         |
    +*             +               +              +              +               +              +
 -4 A+-------------+---------------+--------------+--------------+---------------+-------------++
  05:06          05:06           05:07          05:07          05:08           05:08          05:09



  10 ++---------+-----------+----------+-----------+----------+----------+-----------+---------++
     +          +           +          +           +          +          +           +          +
     |                                                                                       ***A
     |                                                                               ********   |
     |                                                                       ********           |
   8 ++                                                             *****A***                  ++
     |                                                   ***********                            |
     |                                          ***A*****                                       |
     |                                  ********                                                |
     |                          ********                                                        |
   6 ++                     A***                                                               ++
     |                     *                                                                    |
     |                    *                                                                     |
     |                   *                                                                      |
     |                  *                                                                       |
   4 ++                *                                                                       ++
     |                *                                                                         |
     |                *                                                                         |
     |               *                                                                          |
     |              *                                                                           |
   2 ++            *                                                                           ++
     |            *                                                                             |
     |           *                                                                              |
     |          *                                                                               |
     |         *                                                                                |
   0 ++       *                                                                                ++
     |       *                                                                                  |
     |      *                                                                                   |
     |     *                                                                                    |
     |     *                                                                                    |
  -2 ++   *                                                                                    ++
     |   *                                                                                      |
     |  *                                                                                       |
     | *                                                                                        |
     +*         +           +          +           +          +          +           +          +
  -4 A+---------+-----------+----------+-----------+----------+----------+-----------+---------++
   05:06      05:06       05:07      05:07       05:08      05:08      05:09       05:09      05:10



  10 ++----------------+-----------------+------------------+-----------------+-------------****A
     +                 +                 +                  +                 +    *********    +
     |                                                                     ***A****             |
     |                                                               ******                     |
     |                                                         ******                           |
   8 ++                                                 ****A**                                ++
     |                                        **********                                        |
     |                                ***A****                                                  |
     |                          ******                                                          |
     |                    ******                                                                |
   6 ++                A**                                                                     ++
     |                *                                                                         |
     |                *                                                                         |
     |               *                                                                          |
     |              *                                                                           |
   4 ++            *                                                                           ++
     |             *                                                                            |
     |            *                                                                             |
     |           *                                                                              |
     |           *                                                                              |
   2 ++         *                                                                              ++
     |         *                                                                                |
     |        *                                                                                 |
     |        *                                                                                 |
     |       *                                                                                  |
   0 ++     *                                                                                  ++
     |     *                                                                                    |
     |     *                                                                                    |
     |    *                                                                                     |
     |   *                                                                                      |
  -2 ++  *                                                                                     ++
     |  *                                                                                       |
     | *                                                                                        |
     |*                                                                                         |
     +*                +                 +                  +                 +                 +
  -4 A+----------------+-----------------+------------------+-----------------+----------------++
   05:06             05:07             05:08              05:09             05:10             05:11

EOF

}



sub tryplot
{
  my %args = @_;

  my @options = ('--exit',
                 '--extracmds', 'unset grid',
                 '--terminal', 'dumb 100,40');
  unshift @options, @{$args{options}};

  my $feedgnuplot = dirname($0) . "/../bin/feedgnuplot";
  my $out = '';
  my $err = '';
  open IN, '-|', $args{cmd} or die "Couldn't open pipe to $args{cmd}";
  run [$feedgnuplot, @options],
    \*IN, \$out, \$err;

  note( "Running test '$args{testname}'. Running: $args{cmd} | $feedgnuplot " .
        shell_quote(@options));
  is($err, '',             "$args{testname} stderr" );
  is($out, $args{refplot}, "$args{testname} stdout");
}
