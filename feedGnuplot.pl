#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Time::HiRes qw( usleep );
use IO::Handle;
use List::MoreUtils qw( first_index );
use threads;
use threads::shared;
use Thread::Queue;
use Text::ParseWords;

open(GNUPLOT_VERSION, 'gnuplot --version |');
my ($gnuplotVersion) = <GNUPLOT_VERSION> =~ /gnuplot\s*(\d*\.\d*)/;
if(!$gnuplotVersion)
{
  print STDERR "Couldn't find the version of gnuplot. Does it work? Trying anyway...\n";
  $gnuplotVersion = 0;
}

close(GNUPLOT_VERSION);

my $usage = <<OEF;
Usage: $0 [options] file1 file2 ...
  any number of data files can be given on the cmdline. They will be processed
  in sequence. If no data files are given, data will be read in from standard
  input.

  --[no]domain         If enabled, the first element of each line is the
                       domain variable.  If not, the point index is used

  --[no]dataid         If enabled, each data point is preceded by the ID
                       of the data set that point corresponds to. This ID is
                       interpreted as a string, NOT as just a number. If not
                       enabled, the order of the point is used.

As an example, if line 3 of the input is "0 9 1 20"
 '--nodomain --nodataid' would parse the 4 numbers as points in 4
   different curves at x=3

 '--domain --nodataid' would parse the 4 numbers as points in 3 different
   curves at x=0. Here, 0 is the x-variable and 9,1,20 are the data values

 '--nodomain --dataid' would parse the 4 numbers as points in 2 different
   curves at x=3. Here 0 and 1 are the data IDs and 9 and 20 are the
   data values

 '--domain --dataid' would parse the 4 numbers as a single point at
   x=0. Here 9 is the data ID and 1 is the data value. 20 is an extra
   value, so it is ignored. If another value followed 20, we'd get another
   point in curve ID 20

  --[no]3d             Do [not] plot in 3D. This only makes sense with --domain.
                       Each domain here is an (x,y) tuple

  --[no]stream         Do [not] display the data a point at a time, as it
                       comes in

  --[no]lines          Do [not] draw lines to connect consecutive points

  --[no]points         Do [not] draw points

  --xlabel xxx         Set x-axis label
  --ylabel xxx         Set y-axis label
  --y2label xxx        Set y2-axis label. Does not apply to 3d plots
  --zlabel xxx         Set y-axis label. Only applies to 3d plots

  --title  xxx         Set the title of the plot

  --legend xxx         Set the label for a curve plot. Give this option multiple
                       times for multiple curves

  --autolegend         Use the curve IDs for the legend

  --xlen xxx           Set the size of the x-window to plot. Omit this or set it
                       to 0 to plot ALL the data. Does not make sense with 3d plots

  --xmin  xxx          Set the range for the x axis. These are ignored in a
                       streaming plot
  --xmax  xxx          Set the range for the x axis. These are ignored in a
                       streaming plot
  --ymin  xxx          Set the range for the y axis.
  --ymax  xxx          Set the range for the y axis.
  --y2min xxx          Set the range for the y2 axis. Does not apply to 3d plots.
  --y2max xxx          Set the range for the y2 axis. Does not apply to 3d plots.
  --zmin  xxx          Set the range for the z axis. Only applies to 3d plots.
  --zmax  xxx          Set the range for the z axis. Only applies to 3d plots.

  --y2    xxx          Plot the data specified by this curve ID on the y2 axis.
                       Without --dataid, the ID is just an ordered 0-based index.
                       Does not apply to 3d plots.

  --curvestyle xxx     Additional style per curve. Give this option multiple
                       times for multiple curves

  --extracmds xxx      Additional commands. These could contain extra global styles
                       for instance

  --size  xxx          Gnuplot size option

  --square             Plot data with aspect ratio 1

  --hardcopy xxx       If not streaming, output to a file specified here. Format
                       inferred from filename

  --maxcurves xxx      The maximum allowed number of curves. This is 100 by default,
                       but can be reset with this option. This exists purely to
                       prevent perl from allocating all of the system's memory when
                       reading bogus data

  --monotonic          If --domain is given, checks to make sure that the x-
                       coordinate in the input data is monotonically increasing.
                       If a given x-variable is in the past, all data currently
                       cached for this curve is purged. Without --monotonic, all
                       data is kept. Does not make sense with 3d plots.
                       No --monotonic by default.

  --dump               Instead of printing to gnuplot, print to STDOUT. For
                       debugging.
OEF

# if I'm using a self-plotting data file with a #! line, then $ARGV[0] will contain ALL of the
# options and $ARGV[1] will contain the data file to plot. In this case I need to split $ARGV[0] so
# that GetOptions() can parse it correctly. On the other hand, if I'm plotting normally (not with
# #!)  a file with spaces in the filename, I don't want to split the filename. Hopefully this logic
# takes care of both those cases.
if(exists $ARGV[0] && !-r $ARGV[0])
{
  unshift @ARGV, shellwords shift @ARGV;
}

# everything off by default:
# do not stream in the data by default
# point plotting by default.
# no monotonicity checks by default
my %options = ( maxcurves => 100);

GetOptions(\%options,
           'stream!',
           'domain!',
           'dataid!',
           '3d!',
           'lines!',
           'points!',
           'legend=s@',
           'autolegend!',
           'xlabel=s',
           'ylabel=s',
           'y2label=s',
           'zlabel=s',
           'title=s',
           'xlen=f',
           'ymin=f',
           'ymax=f',
           'xmin=f',
           'xmax=f',
           'y2min=f',
           'y2max=f',
           'zmin=f',
           'zmax=f',
           'y2=s@',
           'curvestyle=s@',
           'extracmds=s@',
           'size=s',
           'square!',
           'hardcopy=s',
           'maxcurves=i',
           'monotonic!',
           'help',
           'dump') or die($usage);

# handle various cmdline-option errors
if( $options{help} )
{
  die($usage);
}

if( $options{'3d'} )
{
  if( !$options{domain} )
  {
    print STDERR "--3d only makes sense with --domain\n";
    die $usage;
  }

  if( defined $options{y2min} || defined $options{y2max} || defined $options{y2} )
  {
    print STDERR "--3d does not make sense with --y2...\n";
    die $usage;
  }

  if( defined $options{xlen} )
  {
    print STDERR "--3d does not make sense with --xlen\n";
    die $usage;
  }

  if( defined $options{monotonic} )
  {
    print STDERR "--3d does not make sense with --monotonic\n";
    die $usage;
  }
}
else
{
  if( defined $options{zmin} || defined $options{zmax} || defined $options{zlabel} )
  {
    print STDERR "--zmin/zmax/zlabel only makes sense with --3d\n";
    die $usage;
  }
}

# set up plotting style
my $style = '';
if($options{lines})  { $style .= 'lines';}
if($options{points}) { $style .= 'points';}

if(!$style) { $style = 'points'; }

# list containing the plot data. Each element is a reference to a list, representing the data for
# one curve. The first 'point' is a hash describing various curve parameters. The rest are all
# references to lists of (x,y) tuples
my @curves = ();

# list mapping curve names to their indices in the @curves list
my %curveIndices = ();

# now start the data acquisition and plotting threads
my $dataQueue;
my $xwindow;

my $streamingFinished : shared = undef;
if($options{stream})
{
  if( $options{hardcopy})
  {
    $options{stream} = undef;
  }

  $dataQueue = Thread::Queue->new();
  my $addThr    = threads->create(\&mainThread);
  my $plotThr   = threads->create(\&plotThread);

  while(<>)
  {
    chomp;

    # place every line of input to the queue, so that the plotting thread can process it. if we are
    # using an implicit domain (x = line number), then we send it on the data queue also, since
    # $. is not meaningful in the plotting thread
    if(!$options{domain})
    {
      $_ .= " $.";
    }
    $dataQueue->enqueue($_);
  }

  $streamingFinished = 1;

  $plotThr->join();
  $addThr->join();
}
else
{
  mainThread();
}



sub plotThread
{
  while(! $streamingFinished)
  {
    sleep(1);
    $dataQueue->enqueue('Plot now');
  }

  $dataQueue->enqueue(undef);

}

sub mainThread
{
    local *PIPE;
    my $dopersist = '';

    if($gnuplotVersion >= 4.3)
    {
      $dopersist = '--persist' if(!$options{stream});
    }

    if(exists $options{dump})
    {
      *PIPE = *STDOUT;
    }
    else
    {
      open PIPE, "|gnuplot $dopersist" || die "Can't initialize gnuplot\n";
    }
    autoflush PIPE 1;

    my $outputfile;
    my $outputfileType;
    if( $options{hardcopy})
    {
      $outputfile = $options{hardcopy};
      ($outputfileType) = $outputfile =~ /\.(ps|pdf|png)$/;
      if(!$outputfileType) { die("Only .ps, .pdf and .png supported\n"); }

      my %terminalOpts =
      ( ps  => 'postscript solid color landscape 10',
        pdf => 'pdfcairo solid color font ",10" size 11in,8.5in',
        png => 'png size 1280,1024' );

      print PIPE "set terminal $terminalOpts{$outputfileType}\n";
      print PIPE "set output \"$outputfile\"\n";
    }
    else
    {
      print PIPE "set terminal x11\n";
    }

    # If a bound isn't given I want to set it to the empty string, so I can communicate it simply to
    # gnuplot
    $options{xmin}  = '' unless defined $options{xmin};
    $options{xmax}  = '' unless defined $options{xmax};
    $options{ymin}  = '' unless defined $options{ymin};
    $options{ymax}  = '' unless defined $options{ymax};
    $options{y2min} = '' unless defined $options{y2min};
    $options{y2max} = '' unless defined $options{y2max};
    $options{zmin}  = '' unless defined $options{zmin};
    $options{zmax}  = '' unless defined $options{zmax};

    print PIPE "set xtics\n";
    if($options{y2})
    {
      print PIPE "set ytics nomirror\n";
      print PIPE "set y2tics\n";
      # if any of the ranges are given, set the range
      print PIPE "set y2range [". $options{y2min} . ":" . $options{y2max} ."]\n" if length( $options{y2min} . $options{y2max} );
    }

    # if any of the ranges are given, set the range
    print PIPE "set xrange [". $options{xmin} . ":" . $options{xmax} ."]\n" if length( $options{xmin} . $options{xmax} );
    print PIPE "set yrange [". $options{ymin} . ":" . $options{ymax} ."]\n" if length( $options{ymin} . $options{ymax} );
    print PIPE "set zrange [". $options{zmin} . ":" . $options{zmax} ."]\n" if length( $options{zmin} . $options{zmax} );
    print PIPE "set style data $style\n";
    print PIPE "set grid\n";

    print(PIPE "set xlabel  \"" . $options{xlabel } . "\"\n") if defined $options{xlabel};
    print(PIPE "set ylabel  \"" . $options{ylabel } . "\"\n") if defined $options{ylabel};
    print(PIPE "set zlabel  \"" . $options{zlabel } . "\"\n") if defined $options{zlabel};
    print(PIPE "set y2label \"" . $options{y2label} . "\"\n") if defined $options{y2label};
    print(PIPE "set title   \"" . $options{title  } . "\"\n") if defined $options{title};

    if($options{square})
    {
      $options{size} = '' unless defined $options{size};
      $options{size} .= ' ratio -1';
    }
    print(PIPE "set size $options{size}\n")                     if defined $options{size};

# For the specified values, set the legend entries to 'title "blah blah"'
    if($options{legend})
    {
      my $id = 0;
      foreach (@{$options{legend}})
      {
        setCurveLabel($id++, $_);
      }
    }

# add the extra curve options
    if($options{curvestyle})
    {
      my $id = 0;
      foreach (@{$options{curvestyle}})
      {
        addCurveOption($id++, $_);
      }
    }

# For the values requested to be printed on the y2 axis, set that
    foreach (@{$options{y2}})
    {
      addCurveOption($_, 'axes x1y2 linewidth 3');
    }

# add the extra global options
    if($options{extracmds})
    {
      foreach (@{$options{extracmds}})
      {
        print(PIPE "$_\n");
      }
    }

    # regexp for a possibly floating point, possibly scientific notation number, fully captured
    my $numRE = qr/([-]?[\d\.]+(?:e[-+]?\d+)?)/io;
    my @domain;
    my $haveNewData;

    # I should be using the // operator, but I'd like to be compatible with perl 5.8
    while( $_ = (defined $dataQueue ? $dataQueue->dequeue() : <>))
    {
      next if /^#/o;

      if($_ ne 'Plot now')
      {
        # parse the incoming data lines. The format is
        # x id0 dat0 id1 dat1 ....
        # where idX is the ID of the curve that datX corresponds to
        #
        # $options{domain} indicates whether the initial 'x' is given or not (if not, the line
        # number is used)
        # $options{dataid} indicates whether idX is given or not (if not, the point order in the
        # line is used)
        # 3d plots require $options{domain}, and dictate "x y" for the domain instead of just "x"

        if($options{domain})
        {
          /$numRE/go or next;
          $domain[0] = $1;
          if($options{'3d'})
          {
            /$numRE/go or next;
            $domain[1] = $1;
          }
        }
        else
        {
          # since $. is not meaningful in the plotting thread if we're using the data queue, we pass
          # $. on the data queue in that case
          if(defined $dataQueue)
          {
            s/ ([\d]+)$//o;
            $domain[0] = $1;
          }
          else
          {
            $domain[0] = $.;
          }
        }

        if($options{dataid})
        {
          while(/(\w+)\s+$numRE/go)
          {
            my $point = $2;

            $haveNewData = 1;
            pushPoint(getCurve($1),
                      [@domain, $point]);
          }
        }
        else
        {
          my $id = 0;
          foreach my $point (/$numRE/go)
          {
            $haveNewData = 1;
            pushPoint(getCurve($id++),
                      [@domain, $point]);
          }
        }
      }

      elsif($options{stream})
      {
        # only redraw a streaming plot if there's new data to plot
        next unless $haveNewData;
        $haveNewData = undef;

        if( $options{xlen} )
        {
          pruneOldData($domain[0] - $options{xlen});
          plotStoredData($domain[0] - $options{xlen}, $domain[0]);
        }
        else
        {
          plotStoredData();
        }
      }
    }

    # finished reading in all of the data
    if($options{stream})
    {
      print PIPE "exit;\n";
      close PIPE;
    }
    else
    {
      plotStoredData();

      if( $options{hardcopy})
      {
        print PIPE "set output\n";
        # sleep until the plot file exists, and it is closed. Sometimes the output is
        # still being written at this point
        usleep(100_000) until -e $outputfile;
        usleep(100_000) until(system("fuser -s \"$outputfile\""));

        print "Wrote output to $outputfile\n";
        return;
      }

      # we persist gnuplot, so we shouldn't need this sleep. However, once
      # gnuplot exist, but the persistent window sticks around, you can no
      # longer interactively zoom the plot. So we still sleep
      sleep(100000);
    }
}

sub pruneOldData
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
  my @extraopts = map {$_->[0]{options}} @nonemptyCurves;

  my $cmd = $options{'3d'} ? 'splot ' : 'plot ';
  print PIPE $cmd . join(', ' , map({ '"-"' . $_} @extraopts) ) . "\n";

  foreach my $buf (@nonemptyCurves)
  {
    # send each point to gnuplot. Ignore the first "point" since it's the
    # curve options
    for my $elem (@{$buf}[1..$#$buf])
    {
      print PIPE "@$elem\n";
    }
    print PIPE "e\n";
  }
}

sub updateCurveOptions
{
  # generates the 'options' string for a curve, based on its legend title and its other options
  # These could be integrated into a single string, but that raises an issue in the no-title
  # case. When no title is specified, gnuplot will still add a legend entry with an unhelpful '-'
  # label. Thus I explicitly do 'notitle' for that case

  my ($curveoptions, $id) = @_;

  my $title;
  $title = $curveoptions->{title} if(defined $curveoptions->{title});
  $title = $id                    if $options{autolegend};

  my $titleoption = defined $title ? "title \"$title\"" : "notitle";
  $curveoptions->{options} = "$curveoptions->{extraoptions} $titleoption";
}

sub getCurve
{
  # This function returns the curve corresponding to a particular label, creating a new curve if
  # necessary

  if(scalar @curves >= $options{maxcurves})
  {
    print STDERR "Tried to exceed the --maxcurves setting.\n";
    print STDERR "Invoke with a higher --maxcurves limit if you really want to do this.\n";
    exit;
  }

  my ($id) = @_;

  if( !exists $curveIndices{$id} )
  {
    push @curves, [{extraoptions => ' '}]; # push a curve with no data and no options
    $curveIndices{$id} =  $#curves;

    updateCurveOptions($curves[$#curves][0], $id);
  }
  return $curves[$curveIndices{$id}];
}

sub addCurveOption
{
  my ($id, $str) = @_;

  my $curve = getCurve($id);
  $curve->[0]{extraoptions} .= "$str ";
  updateCurveOptions($curve->[0], $id);
}

sub setCurveLabel
{
  my ($id, $str) = @_;

  my $curve = getCurve($id);
  $curve->[0]{title} = $str;
  updateCurveOptions($curve->[0], $id);
}

# function to add a point to the plot. Assumes that the curve indexed by $idx already exists
sub pushPoint
{
  my ($curve, $xy) = @_;

  if($options{monotonic})
  {
    if( @$curve > 1 && $xy->[0] < $curve->[$#{$curve}][0] )
    {
      # the x-coordinate of the new point is in the past, so I wipe out all the data for this curve
      # and start anew
      splice( @$curve, 1, @$curve-1 );
    }
  }

  push @$curve, $xy;
}
