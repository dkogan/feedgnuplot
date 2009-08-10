#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Time::HiRes qw( usleep );
use Data::Dumper;

# list containing the plot data. Each element is a hash describing the extra
# plotting options for each curve we're plotting, and the actual data to
# plot for each curve. The length of this list grows as the data comes
# in
my @curves = ();

# stream in the data by default
# point plotting by default
my %options = ( "stream" => 1,
                "points" => 0,
                "lines"  => 0,
                "ymin"   => "",
                "ymax"   => "",
                "y2min"  => "",
                "y2max"  => "");
GetOptions(\%options,
           "stream!",
           "lines!",
           "points!",
           "legend=s@",
           "xlabel=s",
           "ylabel=s",
           "y2label=s",
           "title=s",
           "xlen=i",
           "ymin=f",
           "ymax=f",
           "y2min=f",
           "y2max=f",
           "y2=i@",
           "hardcopy=s",
           "help");

# set up plotting style
my $style = "";
if($options{"lines"})  { $style .= "lines";}
if($options{"points"}) { $style .= "points";}

if(!$style) { $style = "points"; }

sub usage {
    print "Usage: $0 <options>\n";
    print <<OEF;
  --[no]stream         Do [not] display the data a point at a time, as it comes in
  --[no]lines          Do [not] draw lines to connect consecutive points
  --xlabel xxx         Set x-axis label
  --ylabel xxx         Set y-axis label
  --y2label xxx        Set y2-axis label
  --title  xxx         Set the title of the plot
  --legend xxx         Set the label for a curve plot. Give this option multiple times for multiple curves
  --xlen xxx           Set the size of the x-window to plot
  --ymin  xxx          Set the range for the y axis. Both or neither of these have to be specified
  --ymax  xxx          Set the range for the y axis. Both or neither of these have to be specified
  --y2min xxx          Set the range for the y2 axis. Both or neither of these have to be specified
  --y2max xxx          Set the range for the y2 axis. Both or neither of these have to be specified
  --y2    xxx          Plot the data with this index on the y2 axis. These are 0-indexed
  --hardcopy xxx       If not streaming, output to a file specified here. Format inferred from filename
OEF
}

sub main {
    if( defined $options{"help"} )
    {
      usage;
      return;
    }
    if( defined $options{"hardcopy"} && $options{"stream"} )
    {
      usage;
      die("If making a hardcopy, we shouldn't be streaming. Doing nothing\n");
    }
    if( !defined $options{"xlen"} )
    {
      usage;
      die("Must specify the size of the moving x-window. Doing nothing\n");
    }
    my $samples = $options{"xlen"};

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
    print PIPE "set ytics nomirror\n";
    print PIPE "set y2tics\n";
    print PIPE "set yrange [". $options{"ymin"} . ":" . $options{"ymax"} ."]\n" if $options{"y2max"};
    print PIPE "set y2range [". $options{"y2min"} . ":" . $options{"y2max"} ."]\n" if $options{"y2max"};
    print PIPE "set style data $style\n";
    print PIPE "set grid\n";

    print(PIPE "set xlabel  \"" . $options{"xlabel" } . "\"\n") if $options{"xlabel"};
    print(PIPE "set ylabel  \"" . $options{"ylabel" } . "\"\n") if $options{"ylabel"};
    print(PIPE "set y2label \"" . $options{"y2label"} . "\"\n") if $options{"y2label"};
    print(PIPE "set title   \"" . $options{"title"  } . "\"\n") if $options{"title"};

# For the specified values, set the legend entries to 'title "blah blah"'
    if($options{"legend"})
    {
      foreach (@{$options{"legend"}}) { newCurve($_, "") }
    }

# For the values requested to be printed on the y2 axis, set that
    foreach my $y2idx (@{$options{"y2"}})
    {
      my $str = " axes x1y2 linewidth 3";
      if(exists $curves[$y2idx])
      {
        $curves[$y2idx]{"extraopts"} .= $str;
      }
      else
      {
        newCurve("", $str);
      }
    }

    select((select(STDOUT), $| = 1)[0]);
    my $xlast = 0;

    # regexp for a possibly floating point, possibly scientific notation number
    my $numRE = qr/([-]?[0-9\.]+(?:e[-]?[0-9]+)?)/;
    while(<>)
    {
      foreach my $curve (@curves)
      {
        my $buf = $curve->{"data"};

        # get the next datapoint, if there is one
        my $point;
        if(/($numRE)/gc)
        {
          $point = $1;
        }
        # if a point is not defined here, dup the last point we have if
        # possible
        elsif(@$buf)
        {
          $point = @$buf[$#$buf];
        }
        # otherwise we can do nothing with this curve, so we skip it
        else
        {
          next;
        }

        # data buffering (up to stream sample size)
        push @$buf, $point;
        shift @$buf if(@$buf > $samples && $options{"stream"});
      }

      # if any extra data is available, create new curves for it
      while(/($numRE)/gc)
      {
        newCurve("", "", $1);
      }

      plotStoredData($xlast, $samples, *PIPE) if($options{"stream"});
      $xlast++;
    }

    if($options{"stream"})
    {
      print PIPE "exit;\n";
      close PIPE;
    }
    else
    {
      $samples = @{$curves[0]->{"data"}};
      plotStoredData($xlast, $samples, *PIPE);

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
  my ($xlast, $samples, $pipe) = @_;

  my $x0 = $xlast - $samples + 1;
  print $pipe "set xrange [$x0:$xlast]\n";

  my @extraopts = map {$_->{"extraopts"}} @curves;
  print $pipe 'plot ' . join(', ' , map({ '"-"' . $_} @extraopts) ) . "\n";

  foreach my $curve (@curves)
  {
    my $buf = $curve->{"data"};
    # if the buffer isn't yet complete, skip the appropriate number of points
    my $x = $x0 + $samples - @$buf;
    for my $elem (@$buf) {
      print $pipe "$x $elem\n";
      $x++;
    }
    print PIPE "e\n";
  }
}

sub newCurve()
{
  my ($title, $opts, $newpoint) = @_;
  if($title) { $opts = "title \"$title\" $opts" }
  else       { $opts = "notitle $opts" }

  my $data = [];
  if (defined $newpoint)
  {
    my $numpoints = 1;
    if (@curves) {
      $numpoints = @{$curves[0]->{"data"}};
    }
    $data = [($newpoint) x $numpoints]
  }
  push ( @curves,
         {"extraopts" => " $opts",
          "data"      => $data} );
}

main;
