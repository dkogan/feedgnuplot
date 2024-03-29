#!/usr/bin/perl

# This tests various features of feedgnuplot. Note that the tests look at actual
# plot output using the 'dumb' terminal, so any changes in gnuplot itself that
# change the way the output looks will show up as test failures. Currently the
# reference plots come from gnuplot 5.4, and I make sure this is the version
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
    print("1..0 # Skip: gnuplot not installed. Tests require ver. 5.4; feedgnuplot works with any.\n");
    exit(0);
  }

  chomp $gnuplotVersion;
  if ($gnuplotVersion ne "gnuplot 5.4 patchlevel 1")
  {
    print("1..0 # Skip: tests require gnuplot 5.4. Instead I detected '$gnuplotVersion'.\n");
    exit(0);
  }
}

use Test::More tests => 94;
use File::Temp 'tempfile';
use IPC::Run 'run';
use String::ShellQuote;
use FindBin qw($Bin);

tryplot( testname => 'basic line plot',
         cmd      => 'seq 5',
         options  => [qw(--lines --points)],
         refplot  => 'basic-line-plot.ref' );

tryplot( testname => 'basic line plot to piped hardcopy',
         cmd      => 'seq 5',
         options  => [qw(--lines --points),
                      '--hardcopy', '|cat'],
         refplot  => 'basic-line-plot-to-piped-hardcopy.ref' );

tryplot( testname => 'basic lines-only plot',
         cmd      => 'seq 5',
         options  => [qw(--lines)],
         refplot  => 'basic-lines-only-plot.ref' );

tryplot( testname => 'basic points-only plot',
         cmd      => 'seq 5',
         options  => [qw(--points)],
         refplot  => 'basic-points-only-plot.ref' );

tryplot( testname => 'basic line plot with bounds',
         cmd      => 'seq 5',
         options  => [qw(--lines --points),
                      qw(--xmin -10.5 --xmax 4.5 --ymin -0.5 --ymax 5.5)],
         refplot  => 'basic-line-plot-with-bounds.ref' );

tryplot( testname => 'basic line plot with bounds, square aspect ratio',
         cmd      => 'seq 5',
         options  => [qw(--lines --points),
                      qw(--xmin -10.5 --xmax 4.5 --ymin -0.5 --ymax 5.5 --square)],
         refplot  => 'basic-line-plot-with-bounds-square-aspect-ratio.ref' );

tryplot( testname => 'lines on both axes with labels, legends, titles',
         cmd      => q{seq 5 | gawk '{print 2*$1, $1*$1}'},
         options  => [qw(--lines --points),
                      '--legend', '0', 'data 0',
                      '--title', "Test plot",
                      qw(--y2 1 --y2label y2 --xlabel x --ylabel y --y2max 30)],
         refplot  => 'lines-on-both-axes-with-labels-legends-titles.ref' );

tryplot( testname => 'lines on both axes with labels, legends, titles; different styles',
         cmd      => q{seq 5 | gawk '{print 2*$1, $1*$1}'},
         options  => ['--legend', '0', 'data 0',
                      '--title', "Test plot",
                      qw(--y2 1 --y2label y2 --xlabel x --ylabel y --y2max 30),
                      '--curvestyle', '0', 'with lines',
                      '--curvestyle', '1', 'with points ps 3 pt 7'],
         refplot  => 'lines-on-both-axes-with-labels-legends-titles-different-styles.ref' );

tryplot( testname => 'domain plot',
         cmd      => q{seq 5 | gawk '{print 2*$1, $1*$1}'},
         options  => [qw(--lines --points), '--domain'],
         refplot  => 'domain-plot.ref' );

tryplot( testname => 'dataid plot',
         cmd      => q{seq 5 | gawk '{print 2*$1, $1*$1}'},
         options  => [qw(--lines --points),
                      qw(--dataid --autolegend)],
         refplot  => 'dataid-plot.ref' );

tryplot( testname => '3d spiral with bounds, labels',
         cmd      => q{seq 50 | gawk '{print 2*cos($1/5), sin($1/5), $1}'},
         options  => [qw(--lines --points),
                      qw(--3d --domain --zmin -5 --zmax 45 --zlabel z),
                     '--extracmds', 'set view 60,30'],
         refplot  => '3d-spiral-with-bounds-labels.ref' );

tryplot( testname => '3d spiral with bounds, labels, square xy aspect ratio',
         cmd      => q{seq 50 | gawk '{print 2*cos($1/5), sin($1/5), $1}'},
         options  => [qw(--lines --points),
                      qw(--3d --domain --zmin -5 --zmax 45 --zlabel z),
                     '--extracmds', 'set view 60,30', '--square_xy'],
         refplot  => '3d-spiral-with-bounds-labels-square-xy-aspect-ratio.ref' );

tryplot( testname => 'Monotonicity check',
         cmd      => q{seq 10 | gawk '{print (NR-1)%5,NR}'},
         options  => [qw(--lines --points --domain --monotonic)],
         refplot  => 'monotonicity-check.ref' );


tryplot( testname => 'basic --timefmt plot',
         cmd      => q{seq 5 | gawk '{print strftime("%d %b %Y %T",1382249107+$1,1),$1}'},
         options  => ['--domain', '--timefmt', '%d %b %Y %H:%M:%S'],
         refplot  => 'basic-timefmt-plot.ref' );

tryplot( testname => '--timefmt plot with bounds',
         cmd      => q{seq 5 | gawk '{print strftime("%d %b %Y %T",1382249107+$1,1),$1}'},
         options  => ['--domain', '--timefmt', '%d %b %Y %H:%M:%S',
                      '--xmin', '20 Oct 2013 06:05:00',
                      '--xmax', '20 Oct 2013 06:05:20'],
         refplot  => 'timefmt-plot-with-bounds.ref' );

tryplot( testname => '--timefmt plot with --monotonic',
         cmd      => q{seq 10 | gawk '{x=(NR-1)%5; print strftime("%d %b %Y %T",1382249107+x,1),$1}'},
         options  => ['--domain', '--timefmt', '%d %b %Y %H:%M:%S',
                      '--monotonic'],
         refplot  => 'timefmt-plot-with-monotonic.ref' );

tryplot( testname => '--timefmt with custom rangesize',
         cmd      => q{seq 5 | gawk '{print strftime("%d %b %Y %T",1382249107+$1,1),$1,$1/10}'},
         options  => ['--domain', '--timefmt', '%d %b %Y %H:%M:%S',
                      qw(--with errorbars --rangesizeall 2)],
         refplot  => 'timefmt-with-custom-rangesize.ref' );

tryplot( testname => 'Error bars (using extraValuesPerPoint)',
         cmd      => q{seq 5 | gawk '{print $1,$1,$1/10}'},
         options  => [qw(--domain),
                      qw(--extraValuesPerPoint 1 --with errorbars)],
         refplot  => 'error-bars-using-extravaluesperpoint.ref' );


tryplot( testname => 'Error bars (using rangesizeall)',
         cmd      => q{seq 5 | gawk '{print $1,$1,$1/10}'},
         options  => [qw(--domain),
                      qw(--rangesizeall 2 --with errorbars)],
         refplot  => 'error-bars-using-rangesizeall.ref' );

tryplot( testname => 'Error bars (using tuplesize)',
         cmd      => q{seq 5 | gawk '{print $1,$1,$1/10}'},
         options  => [qw(--domain),
                      qw(--tuplesizeall 3 --with errorbars)],
         refplot  => 'error-bars-using-tuplesize.ref' );

tryplot( testname => 'Error bars (using rangesize, rangesizeall)',
         cmd      => q{seq 5 | gawk '{print $1,"vert",$1,$1/10,"horiz",5-$1,$1-$1/5,$1+$1/20}'},
         options  => [qw(--domain --dataid),
                      qw(--rangesize vert 2 --rangesizeall 3 --with xerrorbars --style vert), 'with errorbars',
                      qw(--xmin 1 --xmax 5 --ymin 0.5 --ymax 5.5)],
         refplot  => 'error-bars-using-rangesize-rangesizeall.ref' );

tryplot( testname => 'Error bars (using tuplesize, tuplesizeall)',
         cmd      => q{seq 5 | gawk '{print $1,"vert",$1,$1/10,"horiz",5-$1,$1-$1/5,$1+$1/20}'},
         options  => [qw(--domain --dataid),
                      qw(--tuplesize vert 3 --tuplesizeall 4 --with xerrorbars --style vert), 'with errorbars',
                      qw(--xmin 1 --xmax 5 --ymin 0.5 --ymax 5.5)],
         refplot  => 'error-bars-using-tuplesize-tuplesizeall.ref' );

tryplot( testname => 'timefmt without vnl',
         cmd      => q{echo -n '# t a b\n1:00 5 6\n1:30 10 6\n2:00 7 6\n2:30 10 9\n'},
         options  => [qw(--lines --points --domain --timefmt), '%H:%M',
                      '--set', 'format x "%H:%M"'],
         refplot  => 'timefmt-without-vnl.ref' );

tryplot( testname => 'timefmt without vnl with style 0 default 1',
         cmd      => q{echo -n '# t a b\n1:00 5 6\n1:30 10 6\n2:00 7 6\n2:30 10 9\n'},
         options  => [qw(--domain --timefmt), '%H:%M',
                      '--set', 'format x "%H:%M"',
                      '--style', '0', 'with lines lt 7'],
         refplot  => 'timefmt-without-vnl-with-style0-default1.ref' );

tryplot( testname => 'timefmt without vnl with style',
         cmd      => q{echo -n '# t a b\n1:00 5 6\n1:30 10 6\n2:00 7 6\n2:30 10 9\n'},
         options  => [qw(--domain --timefmt), '%H:%M',
                      '--set', 'format x "%H:%M"',
                      '--style', '0', 'with lines lt 7',
                      '--style', '1', 'with lines lt 5' ],
         refplot  => 'timefmt-without-vnl-with-style.ref' );

tryplot( testname => 'timefmt with vnl with style 0 default 1',
         cmd      => q{echo -n '# t a b\n1:00 5 6\n1:30 10 6\n2:00 7 6\n2:30 10 9\n'},
         options  => [qw(--domain --timefmt), '%H:%M',
                      '--set', 'format x "%H:%M"',
                      '--vnl',
                      '--style', 'a', 'with lines lt 7'],
         refplot  => 'timefmt-with-vnl-with-style0-default1.ref' );

tryplot( testname => 'timefmt with vnl with style',
         cmd      => q{echo -n '# t a b\n1:00 5 6\n1:30 10 6\n2:00 7 6\n2:30 10 9\n'},
         options  => [qw(--domain --timefmt), '%H:%M',
                      '--set', 'format x "%H:%M"',
                      '--vnl',
                      '--style', 'a', 'with lines lt 7',
                      '--style', 'b', 'with lines lt 5' ],
         refplot  => 'timefmt-with-vnl-with-style.ref' );

my $data_xticlabels = <<EOF;
# x label a b
 5  aaa   2 1
 6  bbb   3 2
10  ccc   5 4
11  ddd   2 1
EOF

tryplot( testname => 'basic xticlabels no domain',
         cmd      => qq{echo "$data_xticlabels" | vnl-filter -p label,a,b},
         options  => ['--vnl',
                      '--xticlabels',
                      '--with', 'boxes fill solid border lt -1',
                      '--ymin', '0'],
         refplot  => 'basic-xticlabels-no-domain.ref' );

tryplot( testname => 'basic xticlabels domain',
         cmd      => qq{echo "$data_xticlabels"},
         options  => [qw(--vnl --domain),
                      '--xticlabels',
                      '--with', 'boxes fill solid border lt -1',
                      '--ymin', '0'],
         refplot  => 'basic-xticlabels-domain.ref' );

tryplot( testname => 'xticlabels clustered',
         cmd      => qq{echo "$data_xticlabels" | vnl-filter -p label,a,b},
         options  => [qw(--vnl),
                      '--xticlabels',
                      '--set', 'style data histogram',
                      '--set', 'style histogram cluster gap 2',
                      '--set', 'style fill solid border lt -1',
                      '--ymin', '0'],
         refplot  => 'xticlabels-clustered.ref' );

tryplot( testname => 'xticlabels styles',
         cmd      => qq{echo "$data_xticlabels"},
         options  => [qw(--vnl --domain),
                      '--xticlabels',
                      '--style', 'a', 'with points',
                      '--style', 'b', 'with lines',
                      '--xmin', '4.5',
                      '--xmax', '11.5',
                      '--ymin', '0',
                      '--ymax', '6'],
         refplot  => 'xticlabels-styles.ref' );

tryplot( testname => 'xticlabels styles with tuplesize',
         cmd      => qq{echo "$data_xticlabels"},
         options  => [qw(--vnl --domain),
                      '--xticlabels',
                      '--tuplesizeall', '3',
                      '--with', 'linespoints pt variable',
                      '--xmin', '4.5',
                      '--xmax', '11.5',
                      '--ymin', '0',
                      '--ymax', '6'],
         refplot  => 'xticlabels-styles-with-tuplesize.ref' );

tryplot( testname => 'equations',
         cmd      => qq{seq 10 15},
         options  => [qw(--equation x),
                      qw(--equation-above x+1),
                      qw(--equation-below x-1),
                      '--with', 'boxes fill solid border lt -1',
                      '--ymin', '0'],
         refplot  => 'equations.ref' );

tryplot( testname => 'everyall',
         cmd      => q{seq 12 | gawk '{print $1,$1+1}'},
         options  => [qw(--points --everyall 2)],
         refplot  => 'everyall.ref' );

tryplot( testname => 'every-individual',
         cmd      => q{seq 12 | gawk '{print $1,$1+1}'},
         options  => [qw(--points --every 0 2 --every 1 3)],
         refplot  => 'every-individual.ref' );

tryplot( testname => 'usingall',
         cmd      => q{seq 12 | gawk '{print $1,$1+1}'},
         options  => [qw(--style 0), 'with points pt variable',
                      qw(--style 1), 'with linespoints pt variable',
                      qw(--usingall 1:2:($2) --unset grid)],
         refplot  => 'usingall.ref' );

tryplot( testname => 'using-individual',
         cmd      => q{seq 12 | gawk '{print $1,$1+1}'},
         options  => [qw(--style 0), 'with points pt variable',
                      qw(--using 0 1:2:($2)),
                      qw(--using 1 1:(12-$2)),
                      qw(--unset grid)],
         refplot  => 'using-individual.ref' );

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

skip "Skipping unreliable tests. Set RUN_ALL_TESTS environment variable to run them all", 20 unless $ENV{RUN_ALL_TESTS};


tryplot( testname => 'Histogram plot',
         cmd      => q{seq 50 | gawk '{print $1*$1}'},
         options  => [qw(--lines --points),
                      qw(--histo 0 --binwidth 50 --ymin 0 --curvestyleall), 'with boxes'],
         refplot  => 'histogram-plot.ref' );

tryplot( testname => 'Cumulative histogram',
         cmd      => q{seq 50 | gawk '{print $1*$1}'},
         options  => [qw(--lines --points),
                      qw(--histo 0 --histstyle cum --binwidth 50 --ymin 0 --curvestyleall), 'with boxes'],
         refplot  => 'cumulative-histogram.ref' );

tryplot( testname => 'Circles',
         cmd      => q{seq 5 | gawk '{print $1,$1,$1/10}'},
         options  => [qw(--circles --domain)],
         refplot  => 'circles.ref' );

tryplot( testname => '--timefmt --histo',
         cmd      => q{seq 10 | gawk '{x=(NR-1)%5; print strftime("%Y-%m-%d--%H:%M:%S",1382249107+x,1)}' | grep -v ':09'},
         options  => ['--timefmt', '%Y-%m-%d--%H:%M:%S', '--histogram', '0','--binwidth', '1',
                      '--set', q{format x "...-%M:%S"},
                      '--ymax', '2.5'],
         refplot  => 'timefmt-histo.ref' );




note( "Starting to run streaming tests. These will take several seconds each" );

# replotting every 1.0 seconds. Data comes in every 1.1 seconds. Two data
# points, and then "exit", so I should have two frames worth of data plotted. I
# pre-send a 0 so that the gnuplot autoscaling is always well-defined
tryplot( testname => 'basic streaming test',
         cmd      => q{seq 500 | gawk 'BEGIN{ print 0; } {print (NR==3)? "exit" : $0; fflush(); system("sleep 1.2");}'},
         options  => [qw(--lines --points --stream)],
         refplot  => 'basic-streaming-test.ref' );

tryplot( testname => 'basic streaming test, twice as fast',
         cmd      => q{seq 500 | gawk 'BEGIN{ print 0; } {print (NR==3)? "exit" : $0; fflush(); system("sleep 0.6");}'},
         options  => [qw(--lines --points --stream 0.4)],
         refplot  => 'basic-streaming-test-twice-as-fast.ref' );


tryplot( testname => 'streaming with --xlen',
         cmd      => q{seq 500 | gawk 'BEGIN{ print 0; } {print (NR==3)? "exit" : $0; fflush(); system("sleep 0.6");}'},
         options  => [qw(--lines --points --stream 0.4 --xlen 1.1)],
         refplot  => 'streaming-with-xlen.ref' );

tryplot( testname => 'streaming with --monotonic',
         cmd      => q{seq 500 | gawk '{if(NR==11) {print "exit";} else {x=(NR-1)%5; if(x==0) {print -1,-1;} print x,NR;}; fflush(); system("sleep 0.6");}'},
         options  => [qw(--lines --points --stream 0.4 --domain --monotonic)],
         refplot  => 'streaming-with-monotonic.ref' );

tryplot( testname => '--timefmt streaming plot with --xlen',
         cmd      => q{seq 5 | gawk 'BEGIN{ print strftime("%d %b %Y %T",1382249107-1,1),-4;} {if(NR==3) {print "exit";} else{ print strftime("%d %b %Y %T",1382249107+$1,1),$1;} fflush(); system("sleep 0.6")}'},
         options  => ['--points', '--lines',
                      '--domain', '--timefmt', '%d %b %Y %H:%M:%S',
                      qw(--stream 0.4 --xlen 3)],
         refplot  => 'timefmt-streaming-plot-with-xlen.ref' );

tryplot( testname => '--timefmt streaming plot with --monotonic',
         cmd      => q{seq 10 | gawk '{x=(NR-1)%5; if(x==0) {print strftime("%d %b %Y %T",1382249107-1,-4),-4;} print strftime("%d %b %Y %T",1382249107+x,1),NR; fflush(); system("sleep 0.6")}'},
         options  => ['--points', '--lines',
                      '--domain', '--timefmt', '%d %b %Y %H:%M:%S',
                      qw(--stream 0.4 --monotonic)],
         refplot  => 'timefmt-streaming-plot-with-monotonic.ref' );

}



sub tryplot
{
  my %args = @_;

  my @options = ('--exit',
                 qw(--unset grid),
                 '--terminal', 'dumb 100,40');
  unshift @options, @{$args{options}};

  my $feedgnuplot = "$Bin/../bin/feedgnuplot";

  note( "Running test '$args{testname}'. Running: $args{cmd} | $feedgnuplot " .
        shell_quote(@options));

  my $out = '';
  my $err = '';
  open IN, '-|', $args{cmd} or die "Couldn't open pipe to $args{cmd}";
  run [$feedgnuplot, @options],
    \*IN, \$out, \$err;

  # Ignore any screen refresh characters gnuplot may be outputting
  $out =~ s/\s*\n//g;

  # Don't complain about mismatched benign warnings
  $err =~ s/^.*?warning: empty [xy] range.*?$\\n//gmi;

  my $refplot_filename = "$Bin/$args{refplot}";
  my $refplot_data     = readfile($refplot_filename);

  is($err, '',                    "$args{testname} stderr" );
  is("\n$out", "\n$refplot_data", "$args{testname} stdout");

  # Enable, to replace the reference plots with what we observe
  if(0)
  {
      if ($out ne $refplot_data)
      {
          print("Overwrite '$refplot_filename'? ");
          my $x = <STDIN>;
          chomp $x;
          if ( !(!$x || $x =~ /^no?$/i) )
          {
              open my $fd, '>', $refplot_filename
                or die "Couldn't open '$refplot_filename' for writing";
              print $fd $out;
              close $fd;

              print("Overwrote '$refplot_filename'\n");
          }
      }
      print("\n\n");
  }
}

sub readfile
{
    my $path = $_[0];

    open my $fd, '<', $path or return '';
    local $/ = undef;
    my $dat = <$fd>;
    close $fd;
    return $dat;
}
