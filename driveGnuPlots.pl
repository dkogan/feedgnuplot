#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Time::HiRes qw( usleep );
use Data::Dumper;

# stream in the data by default
# point plotting by default
my %options = ( "stream" => 1,
                "points" => 0,
                "lines"  => 0,);
GetOptions(\%options,
           "stream!",
           "lines!",
           "legend=s@",
           "xlabel=s",
           "ylabel=s",
           "y2label=s",
           "title=s",
           "y2min=f",
           "y2max=f",
           "y2=i@",
           "hardcopy=s");

# set up plotting style
my $style = "";
if($options{"lines"})  { $style .= "lines";}
if($options{"points"}) { $style .= "points";}

if(!$style) { $style = "points"; }

sub usage {
    print "Usage: $0 <options>\n";
    print <<OEF;
where mandatory options are (in order):

  NumberOfStreams                       How many streams to plot
  Stream_WindowSampleSize               this many samples
  Stream_YRangeMin Stream_YRangeMax     Min and Max y values

also
  --[no]stream         Do [not] display the data a point at a time, as it comes in
  --[no]lines          Do [not] draw lines to connect consecutive points
  --xlabel xxx         Set x-axis label
  --ylabel xxx         Set y-axis label
  --y2label xxx        Set y2-axis label
  --title  xxx         Set the title of the plot
  --legend xxx         Set the label for a curve plot. Give this option multiple times for multiple curves
  --y2min xxx          Set the range for the y2 axis. Both or neither of these have to be specified
  --y2max xxx          Set the range for the y2 axis. Both or neither of these have to be specified
  --y2    xxx          Plot the data with this index on the y2 axis. These are 0-indexed
  --hardcopy xxx       If not streaming, output to a file specified here. Format inferred from filename
OEF
}

sub Arg {
    if ($#ARGV < $_[0]) {
        print "Expected parameter missing...\n\n";
        usage;
        die("Error parsing args\n");
    }
    $ARGV[int($_[0])];
}

sub main {
    if(  defined $options{"y2min"} && !defined $options{"y2max"} ||
        !defined $options{"y2min"} &&  defined $options{"y2max"} )
    {
      usage;
      die("Both or neither of y2min,y2max should be specified\n");
    }
    if( defined $options{"hardcopy"} && $options{"stream"} )
    {
      die("If making a hardcopy, we shouldn't be streaming. Doing nothing\n");
    }

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
    my $temphardcopyfile;
    my $outputfile;
    my $outputfileType;
    if( defined $options{"hardcopy"})
    {
      $outputfile = $options{"hardcopy"};
      ($outputfileType) = $outputfile =~ /\.(ps|pdf|png)$/;
      if(!$outputfileType) { die("Only .ps, .pdf and .png supported\n"); }

      if ($outputfileType eq "png")
      {
        print PIPE "set terminal png\n";
      }
      else
      {
        print PIPE "set terminal postscript solid color landscape 10\n";
      }
# write to a temporary file first
      $temphardcopyfile = $outputfile;
      $temphardcopyfile =~ s{/}{_}g;
      $temphardcopyfile = "/tmp/$temphardcopyfile";
      print PIPE "set output \"$temphardcopyfile\"\n";
    }

    print PIPE "set xtics\n";
    print PIPE "set ytics\n";
    print PIPE "set y2tics\n";
    print PIPE "set yrange [". $miny . ":" . $maxy ."]\n";
    print PIPE "set y2range [". $options{"y2min"} . ":" . $options{"y2max"} ."]\n" if $options{"y2max"};
    print PIPE "set style data $style\n";
    print PIPE "set grid\n";

    print(PIPE "set xlabel  \"" . $options{"xlabel" } . "\"\n") if $options{"xlabel"};
    print(PIPE "set ylabel  \"" . $options{"ylabel" } . "\"\n") if $options{"ylabel"};
    print(PIPE "set y2label \"" . $options{"y2label"} . "\"\n") if $options{"y2label"};
    print(PIPE "set title   \"" . $options{"title"  } . "\"\n") if $options{"title"};

# For the specified values, set the legend entries to 'title "blah
# blah"'. Otherwise, "notitle".
    my @extraopts;
    @extraopts = map({"title \"$_\""} @{$options{"legend"}}) if($options{"legend"});
    push @extraopts, ("notitle") x ($numberOfStreams - @extraopts);

# For the values requested to be printed on the y2 axis, set that
    foreach my $y2idx (@{$options{"y2"}}) { $extraopts[$y2idx] .= " axes x1y2 linewidth 3"; }

# This is ugly, but "([]) x $numberOfStreams" was giving me references into a single physical list
    for(my $i=0; $i<$numberOfStreams; $i++) {
      push @buffers, [];
    }

    my $streamIdx = 0;
    select((select(STDOUT), $| = 1)[0]);
    my $xlast = 0;

    # regexp for a possibly floating point, possibly scientific notation number
    my $numRE = qr/([-]?[0-9\.]+(?:e[-]?[0-9]+)?)/;
    while(<>)
    {
      chomp;
      my $line = $_;
      foreach my $point ($line =~ /$numRE/g) {
        my $buf = $buffers[$streamIdx];

        # data buffering (up to stream sample size)
        push @{$buf}, $point;
        shift @{$buf} if(@{$buf} > $samples && $options{"stream"});

        $streamIdx++;
        if ($streamIdx == $numberOfStreams) {
          $streamIdx = 0;
          plotStoredData($xlast, $samples, $numberOfStreams, *PIPE, \@buffers, \@extraopts) if($options{"stream"});
          $xlast++;
        }
      }
    }

    if($options{"stream"})
    {
      print PIPE "exit;\n";
      close PIPE;
    }
    else
    {
      $samples = @{$buffers[0]};
      plotStoredData($xlast, $samples, $numberOfStreams, *PIPE, \@buffers, \@extraopts);

      if( defined $options{"hardcopy"})
      {
        print PIPE "set output\n";
        # sleep until the plot file exists, and it is closed. Sometimes the output is
        # still being written at this point
        usleep(100_000) until -e $temphardcopyfile;
        usleep(100_000) until(system("fuser -s $temphardcopyfile"));

        if($outputfileType eq "pdf")
        {
          system("ps2pdf $temphardcopyfile $outputfile");
        }
        else
        {
          system("mv $temphardcopyfile $outputfile");
        }
        printf "Wrote output to $outputfile\n";
        return;
      }
    }
    sleep 100000;
}

sub plotStoredData
{
  my ($xlast, $samples, $numberOfStreams, $pipe, $buffers, $extraopts) = @_;

  my $x0 = $xlast - $samples + 1;
  print $pipe "set xrange [$x0:$xlast]\n";
  print $pipe 'plot ' . join(', ' , map({ "\"-\" $_"} @$extraopts) ) . "\n";

  foreach my $buf (@{$buffers})
  {
    # if the buffer isn't yet complete, skip the appropriate number of points
    my $x = $x0 + $samples - @{$buf};
    for my $elem (@{$buf}) {
      print $pipe "$x $elem\n";
      $x++;
    }
    print PIPE "e\n";
  }
}


main;
