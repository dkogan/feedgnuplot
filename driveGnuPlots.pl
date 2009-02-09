#!/usr/bin/perl -w
use strict;
use Getopt::Long;

# point plotting by default
my %options = ( "lines" => 0);
GetOptions(\%options,
           "lines!");

# set up plotting style
my $style = "points";
$style = "linespoints" if($options{"lines"});

sub usage {
    print "Usage: $0 <options>\n";
    print <<OEF;
where mandatory options are (in order):

  NumberOfStreams                       How many streams to plot
  Stream_WindowSampleSize               this many samples
  Stream_YRangeMin Stream_YRangeMax     Min and Max y values

OEF
    exit(1);
}

sub Arg {
    if ($#ARGV < $_[0]) {
        print "Expected parameter missing...\n\n";
        usage;
    }
    $ARGV[int($_[0])];
}

sub plotHeader
{
  my ($xcounter, $samples, $numberOfStreams, $pipe) = @_;
  #print "stream $streamIdx: ";
  print $pipe "set xrange [".($xcounter-$samples).":".($xcounter+1)."]\n";
  print $pipe 'plot ' . join(', ' , ('"-" notitle') x $numberOfStreams) . "\n";
}

sub main {
    my $argIdx = 0;
    my $numberOfStreams = Arg($argIdx++);
    print "Will display $numberOfStreams Streams...\n";

    my $samples = Arg($argIdx++);
    print "Will use a window of $samples samples\n";

    my $miny = Arg($argIdx++);
    my $maxy = Arg($argIdx++);
    print "Will use a range of [$miny, $maxy]\n";

    my @buffers;
    shift @ARGV; # number of streams
    shift @ARGV; # sample size
    shift @ARGV; # miny
    shift @ARGV; # maxy
    local *PIPE;

    open PIPE, "|gnuplot" || die "Can't initialize gnuplot\n";

    select((select(PIPE), $| = 1)[0]);
    print PIPE "set xtics\n";
    print PIPE "set ytics\n";
    print PIPE "set yrange [". $miny . ":" . $maxy ."]\n";
    print PIPE "set style data $style\n";
    print PIPE "set grid\n";

    for(my $i=0; $i<$numberOfStreams; $i++) {
      my @data = [];
      push @buffers, @data;
    }

    my $streamIdx = 0;
    select((select(STDOUT), $| = 1)[0]);
    my $xcounter = 0;
    while(<>) {
        chomp;
        my $line = $_;
        plotHeader($xcounter, $samples, $numberOfStreams, *PIPE) if($streamIdx == 0);
        foreach my $point ($line =~ /([-]?[0-9\.]+)/g)
        {
          my $buf = $buffers[$streamIdx];

          # data buffering (up to stream sample size)
          push @{$buf}, $point;

          my $cnt = 0;
          for my $elem (reverse @{$buf}) {
            #print " ".$elem;
            print PIPE ($xcounter-$cnt)." ".$elem."\n";
            $cnt++;
          }
          #print "\n";
          print PIPE "e\n";
          if ($cnt>=$samples) {
            shift @{$buf};
          }
          $streamIdx++;
          if ($streamIdx == $numberOfStreams) {
            $streamIdx = 0;
            $xcounter++;
          }
        }
    }
    print PIPE "exit;\n";
    close PIPE;
}

main;
