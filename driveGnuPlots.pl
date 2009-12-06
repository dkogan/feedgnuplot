#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Time::HiRes qw( usleep gettimeofday tv_interval);
use IO::Handle;
use List::MoreUtils qw( first_index );
use Data::Dumper;
use threads;
use Thread::Queue;

my $usage = <<OEF;
Usage: $0 <options>

  --[no]domain         If enabled, the first element of each line is the
                       domain variable.  If not, the point index is used

  --[no]dataindex      If enabled, each data point is preceded by the index
                       of the data set that point corresponds to.  If not
                       enabled, the order of the point is used.

As an example, if line 3 of the input is "0 9 1 20"
 '--nodomain --nodataindex' would parse the 4 numbers as points in 4
   different curves at x=3

 '--domain --nodataindex' would parse the 4 numbers as points in 3 different
   curves at x=0. Here, 0 is the x-variable and 9,1,20 are the data values

 '--nodomain --dataindex' would parse the 4 numbers as points in 2 different
   curves at x=3. Here 0 and 1 are the data indices and 9 and 20 are the
   data values

 '--domain --dataindex' would parse the 4 numbers as a single point at
   x=0. Here 9 is the data index and 1 is the data value. 20 is an extra
   value, so it is ignored. If another value followed 20, we'd get another
   point in curve number


  --[no]stream         Do [not] display the data a point at a time, as it
                       comes in
  --[no]lines          Do [not] draw lines to connect consecutive points
  --[no]points         Do [not] draw points
  --xlabel xxx         Set x-axis label
  --ylabel xxx         Set y-axis label
  --y2label xxx        Set y2-axis label
  --title  xxx         Set the title of the plot
  --legend xxx         Set the label for a curve plot. Give this option multiple
                       times for multiple curves
  --xlen xxx           Set the size of the x-window to plot
  --xmin  xxx          Set the range for the x axis. These are ignored in a
                       streaming plot
  --xmax  xxx          Set the range for the x axis. These are ignored in a
                       streaming plot
  --ymin  xxx          Set the range for the y axis.
  --ymax  xxx          Set the range for the y axis.
  --y2min xxx          Set the range for the y2 axis.
  --y2max xxx          Set the range for the y2 axis.
  --y2    xxx          Plot the data with this index on the y2 axis. These are
                       0-indexed
  --hardcopy xxx       If not streaming, output to a file specified here. Format
                       inferred from filename
  --dump               Instead of printing to gnuplot, print to STDOUT. For
                       debugging.
OEF

# stream in the data by default
# point plotting by default
my %options = ( "stream"    => 1,
                "domain"    => 0,
                "dataindex" => 0,
                "points"    => 0,
                "lines"     => 0,
                "ymin"      => "",
                "ymax"      => "",
                "y2min"     => "",
                "y2max"     => "");
GetOptions(\%options,
           "stream!",
           "domain!",
           "dataindex!",
           "lines!",
           "points!",
           "legend=s@",
           "xlabel=s",
           "ylabel=s",
           "y2label=s",
           "title=s",
           "xlen=f",
           "ymin=f",
           "ymax=f",
           "xmin=f",
           "xmax=f",
           "y2min=f",
           "y2max=f",
           "y2=i@",
           "hardcopy=s",
           "help",
           "dump") or die($usage);

# set up plotting style
my $style = "";
if($options{"lines"})  { $style .= "lines";}
if($options{"points"}) { $style .= "points";}

if(!$style) { $style = "points"; }

if( defined $options{"help"} )
{
  die($usage);
}


# list containing the plot data. Each element is a reference to a list,
# representing the data for one curve. The first "point" is a string of plot
# options
my @curves = ();

# now start the data acquisition and plotting threads
my $dataQueue;
my $xwindow;

if($options{"stream"})
{
  if( defined $options{"hardcopy"})
  {
    $options{"stream"} = undef;
  }
  if( !defined $options{"xlen"} )
  {
    die("$usage\nMust specify the size of the moving x-window. Doing nothing\n");
  }
  $xwindow = $options{"xlen"};

  $dataQueue = Thread::Queue->new();
  my $addThr    = threads->create(\&mainThread);
  my $plotThr   = threads->create(\&plotThread);

  while(<>)
  {
    # place every line of input to the queue, so that the plotting thread can process it.
    $dataQueue->enqueue($_);

    # if we are using an implicit domain (x = line number), then we send it on the data queue also,
    # since $. is not meaningful in the plotting thread
    if(!$options{domain})
    {
      $dataQueue->enqueue($.);
    }
  }

  $dataQueue->enqueue("Plot now");
  $dataQueue->enqueue(undef);

  $addThr->join();
  $plotThr->join();
}
else
{
  mainThread();
}



sub plotThread
{
  while(1)
  {
    sleep(1);
    $dataQueue->enqueue("Plot now");
  }
}

sub mainThread {
    local *PIPE;
    my $dopersist = "";
    $dopersist = "--persist" if(!$options{"stream"});

    if(exists $options{"dump"})
    {
      *PIPE = *STDOUT;
    }
    else
    {
      open PIPE, "|gnuplot $dopersist" || die "Can't initialize gnuplot\n";
    }
    autoflush PIPE 1;

    my $temphardcopyfile;
    my $outputfile;
    my $outputfileType;
    if( defined $options{"hardcopy"})
    {
      $outputfile = $options{"hardcopy"};
      ($outputfileType) = $outputfile =~ /\.(ps|pdf|png)$/;
      if(!$outputfileType) { die("Only .ps, .pdf and .png supported\n"); }

# write to a temporary file first
      $temphardcopyfile = $outputfile;
      $temphardcopyfile =~ s{/}{_}g;
      $temphardcopyfile = "/tmp/$temphardcopyfile";
      if ($outputfileType eq "png")
      {
        print PIPE "set terminal png\n";
        $temphardcopyfile .= '.png';
      }
      else
      {
        print PIPE "set terminal postscript solid color landscape 10\n";
        $temphardcopyfile .= '.ps';
      }
      print PIPE "set output \"$temphardcopyfile\"\n";
    }
    else
    {
      print PIPE "set terminal x11\n";
    }

    print PIPE "set xtics\n";
    if($options{"y2"})
    {
      print PIPE "set ytics nomirror\n";
      print PIPE "set y2tics\n";
      print PIPE "set y2range [". $options{"y2min"} . ":" . $options{"y2max"} ."]\n" if( $options{"y2min"} || $options{"y2max"} );
    }
    print PIPE "set xrange [". $options{"xmin"} . ":" . $options{"xmax"} ."]\n" if( $options{"xmin"} || $options{"xmax"} );;
    print PIPE "set yrange [". $options{"ymin"} . ":" . $options{"ymax"} ."]\n" if( $options{"ymin"} || $options{"ymax"} );;
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
        $curves[$y2idx][0] .= $str;
      }
      else
      {
        newCurve("", $str, undef, $y2idx);
      }
    }

    # regexp for a possibly floating point, possibly scientific notation number, fully captured
    my $numRE = qr/([-]?[0-9\.]+(?:e[-]?[0-9]+)?)/o;
    my $xlast;
    my $haveNewData;

    while( $_ = ($dataQueue && $dataQueue->dequeue()) // <> )
    {
      if($_ ne "Plot now")
      {
        $haveNewData = 1;

        # parse the incoming data lines. The format is
        # x idx0 dat0 idx1 dat1 ....
        # where idxX is the index of the curve that datX corresponds to
        #
        # $options{domain} indicates whether the initial 'x' is given or not (if not, the line
        # number is used)
        # $options{dataindex} indicates whether idxX is given or not (if not, the point order in the
        # line is used)

        if($options{domain})
        {
          /$numRE/go or next;
          $xlast = $1;
        }
        else
        {
          # since $. is not meaningful in the plotting thread if we're using the data queue, we pass
          # $. on the data queue in that case. This construct pulls it from the queue if we're using
          # it, otherwise it uses $. directly
          $xlast = ($dataQueue && $dataQueue->dequeue()) // $.;
        }

        if($options{dataindex})
        {
          while(/([0-9]+)\s+$numRE/go)
          {
            my $idx   = $1;
            my $point = $2;

            newCurve("", "", undef, $idx) unless exists $curves[$idx];

            push @{$curves[$idx]}, [$xlast, $point];
          }
        }
        else
        {
          my $idx = 0;
          foreach my $point (/$numRE/go)
          {
            newCurve("", "", undef, $idx) unless exists $curves[$idx];

            push @{$curves[$idx]}, [$xlast, $point];
            $idx++;
          }
        }
      }

      elsif($options{"stream"} && defined $xlast)
      {
        next unless $haveNewData;
        $haveNewData = undef;

        cutOld($xlast - $xwindow);
        plotStoredData($xlast - $xwindow, $xlast);
      }
    }

    # read in all of the data
    if($options{"stream"})
    {
      print PIPE "exit;\n";
      close PIPE;
    }
    else
    {
      plotStoredData();

      if( defined $options{"hardcopy"})
      {
        print PIPE "set output\n";
        # sleep until the plot file exists, and it is closed. Sometimes the output is
        # still being written at this point
        usleep(100_000) until -e $temphardcopyfile;
        usleep(100_000) until(system("fuser -s $temphardcopyfile"));

        print "Finished gnuplotting. Converting...\n";
        if($outputfileType eq "pdf")
        {
          system("ps2pdf $temphardcopyfile $outputfile");
        }
        else
        {
          system("mv $temphardcopyfile $outputfile");
        }
        print "Wrote output to $outputfile\n";
        return;
      }

      # we persist gnuplot, so we shouldn't need this sleep. However, once
      # gnuplot exist, but the persistent window sticks around, you can no
      # longer interactively zoom the plot. So we still sleep
      sleep(100000);
    }
}

sub cutOld
{
  my ($oldestx) = @_;

  foreach my $xy (@curves)
  {
    if( @$xy > 1 )
    {
      my $firstInWindow = first_index {$_->[0] >= $oldestx} @{$xy}[1..$#$xy];
      splice( @$xy, 1, $firstInWindow ) unless $firstInWindow == -1;
    }
  }
}

sub plotStoredData
{
  my ($xmin, $xmax) = @_;
  print PIPE "set xrange [$xmin:$xmax]\n" if defined $xmin;

  # get the options for those curves that have any data
  my @nonemptyCurves = grep {@$_ > 1} @curves;
  my @extraopts = map {$_->[0]} @nonemptyCurves;

  print PIPE 'plot ' . join(', ' , map({ '"-"' . $_} @extraopts) ) . "\n";

  foreach my $buf (@nonemptyCurves)
  {
    # send each point to gnuplot. Ignore the first "point" since it's the
    # options string
    for my $elem (@{$buf}[1..$#$buf]) {
      my ($x, $y) = @$elem;
      print PIPE "$x $y\n";
    }
    print PIPE "e\n";
  }
}

sub newCurve()
{
  my ($title, $opts, $newpoint, $idx) = @_;

  # if this curve index doesn't exist, create curve up-to this index
  if(defined $idx)
  {
    while(!exists $curves[$idx])
    {
      pushNewEmptyCurve();
    }
  }
  else
  {
    # if we're not given an index, create a new one at the end, and fill it in
    pushNewEmptyCurve();
    $idx = $#curves;
  }

  if($title) { $opts = "title \"$title\" $opts" }
  else       { $opts = "notitle $opts" }

  if( defined $newpoint )
  {
    $curves[$idx] = [" $opts", $newpoint];
  }
  else
  {
    $curves[$idx] = [" $opts"];
  }
}

sub pushNewEmptyCurve
{
  my $opts = "notitle ";
  push @curves, [" $opts"];
}
