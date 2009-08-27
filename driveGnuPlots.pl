#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Time::HiRes qw( usleep gettimeofday tv_interval);
use IO::Handle;
use List::MoreUtils qw( first_index );
use Data::Dumper;
use threads;
use Thread::Queue;

autoflush STDOUT 1;

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

if( defined $options{"help"} )
{
  usage();
  return;
}
if( defined $options{"hardcopy"} && $options{"stream"} )
{
  usage();
  die("If making a hardcopy, we shouldn't be streaming. Doing nothing\n");
}
if( !defined $options{"xlen"} )
{
  usage();
  die("Must specify the size of the moving x-window. Doing nothing\n");
}
my $xwindow = $options{"xlen"};




# now start the data acquisition and plotting threads
my $dataQueue = Thread::Queue->new();
my $addThr    = threads->create(\&mainThread);
my $plotThr   = threads->create(\&plotThread) if(!$options{"stream"});

while(<>)
{
  $dataQueue->enqueue($_);
}

$dataQueue->enqueue("Plot now");
$dataQueue->enqueue(undef);

$addThr->join();
$plotThr->join() if(!$options{"stream"});




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
    open PIPE, "|gnuplot" || die "Can't initialize gnuplot\n";
    autoflush PIPE 1;

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

    # regexp for a possibly floating point, possibly scientific notation number
    my $numRE = qr/([-]?[0-9\.]+(?:e[-]?[0-9]+)?)/;
    my $xlast;
    while( $_ = $dataQueue->dequeue() )
    {
      if(!/Plot now/)
      {
        # parse the incoming data lines. The format is
        # x idx0 dat0 idx1 dat1 ....
        # where idxX is the index of the curve that datX corresponds to
        /($numRE)/gc or next;
        $xlast = $1;

        while(/([0-9]+) ($numRE)/gc)
        {
          my $idx   = $1;
          my $point = $2;

          # if this curve index doesn't exist, create curve up-to this index
          while(!exists $curves[$idx])
          {
            newCurve("", "");
          }

          push @{$curves[$idx]->{"data"}}, [$xlast, $point];
        }
      }

      elsif($options{"stream"})
      {
        cutOld($xlast - $xwindow);
        plotStoredData($xlast - $xwindow, $xlast);
      }
    }

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

sub cutOld
{
  my ($oldestx) = @_;
  foreach (@curves)
  {
    my $xy = $_->{"data"};

    if( @$xy )
    {
      my $firstInWindow = first_index {$_->[0] >= $oldestx} @$xy;
      splice( @$xy, 0, $firstInWindow ) unless $firstInWindow == -1;
    }
  }
}

sub plotStoredData
{
  my ($xmin, $xmax) = @_;
  print PIPE "set xrange [$xmin:$xmax]\n" if defined $xmin;

  my @extraopts = map {$_->{"extraopts"}} grep {@{$_->{"data"}}} @curves;
  print PIPE 'plot ' . join(', ' , map({ '"-"' . $_} @extraopts) ) . "\n";

  foreach my $curve (@curves)
  {
    my $buf = $curve->{"data"};
    next unless @$buf;
    for my $elem (@$buf) {
      my ($x, $y) = @$elem;
      print PIPE "$x $y\n";
    }
    print PIPE "e\n";
  }
}

sub newCurve()
{
  my ($title, $opts, $newpoint) = @_;
  if($title) { $opts = "title \"$title\" $opts" }
  else       { $opts = "notitle $opts" }

  $newpoint = [] unless defined $newpoint;
  push ( @curves,
         {"extraopts" => " $opts",
          "data"      => $newpoint} );
}

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

