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

use Test::More tests => 58;
use File::Temp 'tempfile';
use IPC::Run 'run';
use String::ShellQuote;
use FindBin qw($Bin);


tryplot( testname => 'basic line plot',
         cmd      => 'seq 5',
         options  => [qw(--lines --points)],
         refplot  => readfile('basic-line-plot.ref') );

tryplot( testname => 'basic line plot to piped hardcopy',
         cmd      => 'seq 5',
         options  => [qw(--lines --points),
                      '--hardcopy', '|cat'],
         refplot  => readfile('basic-line-plot-to-piped-hardcopy.ref') );

tryplot( testname => 'basic lines-only plot',
         cmd      => 'seq 5',
         options  => [qw(--lines)],
         refplot  => readfile('basic-lines-only-plot.ref') );

tryplot( testname => 'basic points-only plot',
         cmd      => 'seq 5',
         options  => [qw(--points)],
         refplot  => readfile('basic-points-only-plot.ref') );

tryplot( testname => 'basic line plot with bounds',
         cmd      => 'seq 5',
         options  => [qw(--lines --points),
                      qw(--xmin -10.5 --xmax 4.5 --ymin -0.5 --ymax 5.5)],
         refplot  => readfile('basic-line-plot-with-bounds.ref') );

tryplot( testname => 'basic line plot with bounds, square aspect ratio',
         cmd      => 'seq 5',
         options  => [qw(--lines --points),
                      qw(--xmin -10.5 --xmax 4.5 --ymin -0.5 --ymax 5.5 --square)],
         refplot  => readfile('basic-line-plot-with-bounds-square-aspect-ratio.ref') );

tryplot( testname => 'lines on both axes with labels, legends, titles',
         cmd      => q{seq 5 | gawk '{print 2*$1, $1*$1}'},
         options  => [qw(--lines --points),
                      '--legend', '0', 'data 0',
                      '--title', "Test plot",
                      qw(--y2 1 --y2label y2 --xlabel x --ylabel y --y2max 30)],
         refplot  => readfile('lines-on-both-axes-with-labels-legends-titles.ref') );

tryplot( testname => 'lines on both axes with labels, legends, titles; different styles',
         cmd      => q{seq 5 | gawk '{print 2*$1, $1*$1}'},
         options  => ['--legend', '0', 'data 0',
                      '--title', "Test plot",
                      qw(--y2 1 --y2label y2 --xlabel x --ylabel y --y2max 30),
                      '--curvestyle', '0', 'with lines',
                      '--curvestyle', '1', 'with points ps 3 pt 7'],
         refplot  => readfile('lines-on-both-axes-with-labels-legends-titles-different-styles.ref') );

tryplot( testname => 'domain plot',
         cmd      => q{seq 5 | gawk '{print 2*$1, $1*$1}'},
         options  => [qw(--lines --points), '--domain'],
         refplot  => readfile('domain-plot.ref') );

tryplot( testname => 'dataid plot',
         cmd      => q{seq 5 | gawk '{print 2*$1, $1*$1}'},
         options  => [qw(--lines --points),
                      qw(--dataid --autolegend)],
         refplot  => readfile('dataid-plot.ref') );

tryplot( testname => '3d spiral with bounds, labels',
         cmd      => q{seq 50 | gawk '{print 2*cos($1/5), sin($1/5), $1}'},
         options  => [qw(--lines --points),
                      qw(--3d --domain --zmin -5 --zmax 45 --zlabel z),
                     '--extracmds', 'set view 60,30'],
         refplot  => readfile('3d-spiral-with-bounds-labels.ref') );

tryplot( testname => '3d spiral with bounds, labels, square xy aspect ratio',
         cmd      => q{seq 50 | gawk '{print 2*cos($1/5), sin($1/5), $1}'},
         options  => [qw(--lines --points),
                      qw(--3d --domain --zmin -5 --zmax 45 --zlabel z),
                     '--extracmds', 'set view 60,30', '--square_xy'],
         refplot  => readfile('3d-spiral-with-bounds-labels-square-xy-aspect-ratio.ref') );

tryplot( testname => 'Monotonicity check',
         cmd      => q{seq 10 | gawk '{print (NR-1)%5,NR}'},
         options  => [qw(--lines --points --domain --monotonic)],
         refplot  => readfile('monotonicity-check.ref') );


tryplot( testname => 'basic --timefmt plot',
         cmd      => q{seq 5 | gawk '{print strftime("%d %b %Y %T",1382249107+$1,1),$1}'},
         options  => ['--domain', '--timefmt', '%d %b %Y %H:%M:%S'],
         refplot  => readfile('basic-timefmt-plot.ref') );

tryplot( testname => '--timefmt plot with bounds',
         cmd      => q{seq 5 | gawk '{print strftime("%d %b %Y %T",1382249107+$1,1),$1}'},
         options  => ['--domain', '--timefmt', '%d %b %Y %H:%M:%S',
                      '--xmin', '20 Oct 2013 06:05:00',
                      '--xmax', '20 Oct 2013 06:05:20'],
         refplot  => readfile('timefmt-plot-with-bounds.ref') );

tryplot( testname => '--timefmt plot with --monotonic',
         cmd      => q{seq 10 | gawk '{x=(NR-1)%5; print strftime("%d %b %Y %T",1382249107+x,1),$1}'},
         options  => ['--domain', '--timefmt', '%d %b %Y %H:%M:%S',
                      '--monotonic'],
         refplot  => readfile('timefmt-plot-with-monotonic.ref') );

tryplot( testname => '--timefmt with custom rangesize',
         cmd      => q{seq 5 | gawk '{print strftime("%d %b %Y %T",1382249107+$1,1),$1,$1/10}'},
         options  => ['--domain', '--timefmt', '%d %b %Y %H:%M:%S',
                      qw(--with errorbars --rangesizeall 2)],
         refplot  => readfile('timefmt-with-custom-rangesize.ref') );

tryplot( testname => 'Error bars (using extraValuesPerPoint)',
         cmd      => q{seq 5 | gawk '{print $1,$1,$1/10}'},
         options  => [qw(--domain),
                      qw(--extraValuesPerPoint 1 --with errorbars)],
         refplot  => readfile('error-bars-using-extravaluesperpoint.ref') );


tryplot( testname => 'Error bars (using rangesizeall)',
         cmd      => q{seq 5 | gawk '{print $1,$1,$1/10}'},
         options  => [qw(--domain),
                      qw(--rangesizeall 2 --with errorbars)],
         refplot  => readfile('error-bars-using-rangesizeall.ref') );


tryplot( testname => 'Error bars (using rangesize, rangesizeall)',
         cmd      => q{seq 5 | gawk '{print $1,"vert",$1,$1/10,"horiz",5-$1,$1-$1/5,$1+$1/20}'},
         options  => [qw(--domain --dataid),
                      qw(--rangesize vert 2 --rangesizeall 3 --with xerrorbars --style vert), 'with errorbars',
                      qw(--xmin 1 --xmax 5 --ymin 0.5 --ymax 5.5)],
         refplot  => readfile('error-bars-using-rangesize-rangesizeall.ref') );


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
         refplot  => readfile('histogram-plot.ref') );

tryplot( testname => 'Cumulative histogram',
         cmd      => q{seq 50 | gawk '{print $1*$1}'},
         options  => [qw(--lines --points),
                      qw(--histo 0 --histstyle cum --binwidth 50 --ymin 0 --curvestyleall), 'with boxes'],
         refplot  => readfile('cumulative-histogram.ref') );

tryplot( testname => 'Circles',
         cmd      => q{seq 5 | gawk '{print $1,$1,$1/10}'},
         options  => [qw(--circles --domain)],
         refplot  => readfile('circles.ref') );




note( "Starting to run streaming tests. These will take several seconds each" );

# replotting every 1.0 seconds. Data comes in every 1.1 seconds. Two data
# points, and then "exit", so I should have two frames worth of data plotted. I
# pre-send a 0 so that the gnuplot autoscaling is always well-defined
tryplot( testname => 'basic streaming test',
         cmd      => q{seq 500 | gawk 'BEGIN{ print 0; } {print (NR==3)? "exit" : $0; fflush(); system("sleep 1.2");}'},
         options  => [qw(--lines --points --stream)],
         refplot  => readfile('basic-streaming-test.ref') );

tryplot( testname => 'basic streaming test, twice as fast',
         cmd      => q{seq 500 | gawk 'BEGIN{ print 0; } {print (NR==3)? "exit" : $0; fflush(); system("sleep 0.6");}'},
         options  => [qw(--lines --points --stream 0.4)],
         refplot  => readfile('basic-streaming-test-twice-as-fast.ref') );


tryplot( testname => 'streaming with --xlen',
         cmd      => q{seq 500 | gawk 'BEGIN{ print 0; } {print (NR==3)? "exit" : $0; fflush(); system("sleep 0.6");}'},
         options  => [qw(--lines --points --stream 0.4 --xlen 1.1)],
         refplot  => readfile('streaming-with-xlen.ref') );

tryplot( testname => 'streaming with --monotonic',
         cmd      => q{seq 500 | gawk '{if(NR==11) {print "exit";} else {x=(NR-1)%5; if(x==0) {print -1,-1;} print x,NR;}; fflush(); system("sleep 0.6");}'},
         options  => [qw(--lines --points --stream 0.4 --domain --monotonic)],
         refplot  => readfile('streaming-with-monotonic.ref') );

tryplot( testname => '--timefmt streaming plot with --xlen',
         cmd      => q{seq 5 | gawk 'BEGIN{ print strftime("%d %b %Y %T",1382249107-1,1),-4;} {if(NR==3) {print "exit";} else{ print strftime("%d %b %Y %T",1382249107+$1,1),$1;} fflush(); system("sleep 0.6")}'},
         options  => ['--points', '--lines',
                      '--domain', '--timefmt', '%d %b %Y %H:%M:%S',
                      qw(--stream 0.4 --xlen 3)],
         refplot  => readfile('timefmt-streaming-plot-with-xlen.ref') );

tryplot( testname => '--timefmt streaming plot with --monotonic',
         cmd      => q{seq 10 | gawk '{x=(NR-1)%5; if(x==0) {print strftime("%d %b %Y %T",1382249107-1,-4),-4;} print strftime("%d %b %Y %T",1382249107+x,1),NR; fflush(); system("sleep 0.6")}'},
         options  => ['--points', '--lines',
                      '--domain', '--timefmt', '%d %b %Y %H:%M:%S',
                      qw(--stream 0.4 --monotonic)],
         refplot  => readfile('timefmt-streaming-plot-with-monotonic.ref') );

}



sub tryplot
{
  my %args = @_;

  my @options = ('--exit',
                 qw(--unset grid),
                 '--terminal', 'dumb 100,40');
  unshift @options, @{$args{options}};

  my $feedgnuplot = "$Bin/../bin/feedgnuplot";
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

sub readfile
{
    my $path = "$Bin/$_[0]";

    open my $fd, '<', $path or die "Couldn't open '$path'";
    local $/ = undef;
    my $dat = <$fd>;
    close $fd;
    return $dat;
}
