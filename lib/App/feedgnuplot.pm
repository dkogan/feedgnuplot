package App::feedgnuplot;

our $VERSION = 1.26;

=head1 NAME

feedgnuplot - General purpose pipe-oriented plotting tool

=head1 SYNOPSIS

Simple plotting of piped data:

 $ seq 5 | awk '{print 2*$1, $1*$1}'
 2 1
 4 4
 6 9
 8 16
 10 25

 $ seq 5 | awk '{print 2*$1, $1*$1}' |
   feedgnuplot --lines --points --legend 0 "data 0" --title "Test plot" --y2 1

Simple real-time plotting example: plot how much data is received on the wlan0
network interface in bytes/second (uses bash, awk and Linux):

 $ while true; do sleep 1; cat /proc/net/dev; done |
   gawk '/wlan0/ {if(b) {print $2-b; fflush()} b=$2}' |
   feedgnuplot --lines --stream --xlen 10 --ylabel 'Bytes/sec' --xlabel seconds

=head1 DESCRIPTION

This is a flexible, command-line-oriented frontend to Gnuplot. It creates
plots from data coming in on STDIN or given in a filename passed on the
commandline. Various data representations are supported, as is hardcopy
output and streaming display of live data. A simple example:

 $ seq 5 | awk '{print 2*$1, $1*$1}' | feedgnuplot

You should see a plot with two curves. The C<awk> command generates some data to
plot and the C<feedgnuplot> reads it in from STDIN and generates the plot. The
C<awk> invocation is just an example; more interesting things would be plotted
in normal usage. No commandline-options are required for the most basic
plotting. Input parsing is flexible; every line need not have the same number of
points. New curves will be created as needed.

The most commonly used functionality of gnuplot is supported directly by the
script. Anything not directly supported can still be done with the
C<--extracmds> and C<--curvestyle> options. Arbitrary gnuplot commands can be
passed in with C<--extracmds>. For example, to turn off the grid, pass in
C<--extracmds 'unset grid'>. As many of these options as needed can be passed
in. To add arbitrary curve styles, use C<--curvestyle curveID extrastyle>. Pass
these more than once to affect more than one curve. To apply an extra style to
I<all> the curves that lack an explicit C<--curvestyle>, pass in
C<--curvestyleall extrastyle>.

=head2 Data formats

By default, each value present in the incoming data represents a distinct data
point, as demonstrated in the original example above (we had 10 numbers in the
input and 10 points in the plot). If requested, the script supports more
sophisticated interpretation of input data

=head3 Domain selection

If C<--domain> is passed in, the first value on each line of input is
interpreted as the I<X>-value for the rest of the data on that line. Without
C<--domain> the I<X>-value is the line number, and the first value on a line is
a plain data point like the others. Default is C<--nodomain>. Thus the original
example above produces 2 curves, with B<1,2,3,4,5> as the I<X>-values. If we run
the same command with --domain:

 $ seq 5 | awk '{print 2*$1, $1*$1}' | feedgnuplot --domain

we get only 1 curve, with B<2,4,6,8,10> as the I<X>-values. As many points as
desired can appear on a single line, but all points on a line are associated
with the I<X>-value at the start of that line.

=head3 Curve indexing

By default, each column represents a separate curve. This is fine unless sparse
data is to be plotted. With the C<--dataid> option, each point is represented by
2 values: a string identifying the curve, and the value itself. If we add
C<--dataid> to the original example:

 $ seq 5 | awk '{print 2*$1, $1*$1}' | feedgnuplot --dataid --autolegend

we get 5 different curves with one point in each. The first column, as produced
by C<awk>, is B<2,4,6,8,10>. These are interpreted as the IDs of the curves to
be plotted. The C<--autolegend> option adds a legend using the given IDs to
label the curves. The IDs need not be numbers; generic strings are accepted. As
many points as desired can appear on a single line. C<--domain> can be used in
conjunction with C<--dataid>.

=head3 Multi-value style support

Depending on how gnuplot is plotting the data, more than one value may be needed
to represent a single point. For example, the script has support to plot all the
data with C<--circles>. This requires a radius to be specified for each point in
addition to the position of the point. Thus, when plotting with C<--circles>, 2
numbers are read for each data point instead of 1. A similar situation exists
with C<--colormap> where each point contains the position I<and> the
color. There are other gnuplot styles that require more data (such as error
bars), but none of these are directly supported by the script. They can still be
used, though, by specifying the specific style with C<--curvestyle>, and
specifying how many extra values are needed for each point with
C<--extraValuesPerPoint extra>. C<--extraValuesPerPoint> is ONLY needed for the
styles not explicitly supported; supported styles set that variable
automatically.

=head3 3D data

To plot 3D data, pass in C<--3d>. C<--domain> MUST be given when plotting 3D
data to avoid domain ambiguity. If 3D data is being plotted, there are by
definition 2 domain values instead of one (I<Z> as a function of I<X> and I<Y>
instead of I<Y> as a function of I<X>). Thus the first 2 values on each line are
interpreted as the domain instead of just 1. The rest of the processing happens
the same way as before.

=head3 Time/date data

If the input data domain is a time/date, this can be interpreted with
C<--timefmt>. This option takes a single argument: the format to use to parse
the data. The format is documented in 'set timefmt' in gnuplot, although the
common flags that C<strftime> understands are generally supported. The backslash
sequences in the format are I<not> supported, so if you want a tab, put in a tab
instead of \t. Whitespace in the format I<is> supported. When this flag is
given, some other options act a little bit differently:

=over

=item

C<--xlen> is an I<integer> in seconds

=item

C<--xmin> and C<--xmax> I<must> use the format passed in to C<--timefmt>

=back

Using this option changes both the way the input is parsed I<and> the way the
x-axis tics are labelled. Gnuplot tries to be intelligent in this labelling, but
it doesn't always to what the user wants. The labelling can be controlled with
the gnuplot C<set format> command, which takes the same type of format string as
C<--timefmt>. Example:

 $ sar 1 -1 |
   awk '$1 ~ /..:..:../ && $8 ~/^[0-9\.]*$/ {print $1,$8; fflush()}' |
   feedgnuplot --stream --domain
                --lines --timefmt '%H:%M:%S'
                --extracmds 'set format x "%H:%M:%S"'

This plots the 'idle' CPU consumption against time.

Note that while gnuplot supports the time/date on any axis, I<feedgnuplot>
currently supports it I<only> as the x-axis domain. This may change in the
future.

=head2 Real-time streaming data

To plot real-time data, pass in the C<--stream [refreshperiod]> option. Data
will then be plotted as it is received. The plot will be updated every
C<refreshperiod> seconds. If the period isn't specified, a 1Hz refresh rate is
used. To refresh at specific intervals indicated by the data, set the
refreshperiod to 0 or to 'trigger'. The plot will then I<only> be refreshed when
a data line 'replot' is received. This 'replot' command works in both triggered
and timed modes, but in triggered mode, it's the only way to replot. Look in
L</"Special data commands"> for more information.

To plot only the most recent data (instead of I<all> the data), C<--xlen
windowsize> can be given. This will create an constantly-updating, scrolling
view of the recent past. C<windowsize> should be replaced by the desired length
of the domain window to plot, in domain units (passed-in values if C<--domain>
or line numbers otherwise). If the domain is a time/date via C<--timefmt>, then
C<windowsize> is and I<integer> in seconds.

=head3 Special data commands

If we are reading streaming data, the input stream can contain special commands
in addition to the raw data. Feedgnuplot looks for these at the start of every
input line. If a command is detected, the rest of the line is discarded. These
commands are

=over

=item C<replot>

This command refreshes the plot right now, instead of waiting for the next
refresh time indicated by the timer. This command works in addition to the timed
refresh, as indicated by C<--stream [refreshperiod]>.

=item C<clear>

This command clears out the current data in the plot. The plotting process
continues, however, to any data following the C<clear>.

=item C<exit>

This command causes feedgnuplot to exit.

=back

=head2 Hardcopy output

The script is able to produce hardcopy output with C<--hardcopy outputfile>. The
output type can be inferred from the filename, if B<.ps>, B<.eps>, B<.pdf>,
B<.svg> or B<.png> is requested. If any other file type is requested,
C<--terminal> I<must> be passed in to tell gnuplot how to make the plot.

=head2 Self-plotting data files

This script can be used to enable self-plotting data files. There are 2 ways of
doing this: with a shebang (#!) or with inline perl data.

=head3 Self-plotting data with a #!

A self-plotting, executable data file C<data> is formatted as

 $ cat data
 #!/usr/bin/feedgnuplot --lines --points
 2 1
 4 4
 6 9
 8 16
 10 25
 12 36
 14 49
 16 64
 18 81
 20 100
 22 121
 24 144
 26 169
 28 196
 30 225

This is the shebang (#!) line followed by the data, formatted as before. The
data file can be plotted simply with

 $ ./data

The caveats here are that on Linux the whole #! line is limited to 127 charaters
and that the full path to feedgnuplot must be given. The 127 character limit is
a serious limitation, but this can likely be resolved with a kernel patch. I
have only tried on Linux 2.6.

=head3 Self-plotting data with perl inline data

Perl supports storing data and code in the same file. This can also be used to
create self-plotting files:

 $ cat plotdata.pl
 #!/usr/bin/perl
 use strict;
 use warnings;

 open PLOT, "| feedgnuplot --lines --points" or die "Couldn't open plotting pipe";
 while( <DATA> )
 {
   my @xy = split;
   print PLOT "@xy\n";
 }
 __DATA__
 2 1
 4 4
 6 9
 8 16
 10 25
 12 36
 14 49
 16 64
 18 81
 20 100
 22 121
 24 144
 26 169
 28 196
 30 225

This is especially useful if the logged data is not in a format directly
supported by feedgnuplot. Raw data can be stored after the __DATA__ directive,
with a small perl script to manipulate the data into a useable format and send
it to the plotter.

=head1 ARGUMENTS

=over

=item

--[no]domain

If enabled, the first element of each line is the domain variable. If not, the
point index is used

=item

--[no]dataid

If enabled, each data point is preceded by the ID of the data set that point
corresponds to. This ID is interpreted as a string, NOT as just a number. If not
enabled, the order of the point is used.

As an example, if line 3 of the input is "0 9 1 20" then

=over

=item

'--nodomain --nodataid' would parse the 4 numbers as points in 4 different
curves at x=3

=item

'--domain --nodataid' would parse the 4 numbers as points in 3 different
curves at x=0. Here, 0 is the x-variable and 9,1,20 are the data values

=item

'--nodomain --dataid' would parse the 4 numbers as points in 2 different
curves at x=3. Here 0 and 1 are the data IDs and 9 and 20 are the
data values

=item

'--domain --dataid' would parse the 4 numbers as a single point at
x=0. Here 9 is the data ID and 1 is the data value. 20 is an extra
value, so it is ignored. If another value followed 20, we'd get another
point in curve ID 20

=back

=item

--[no]3d

Do [not] plot in 3D. This only makes sense with --domain. Each domain here is an
(x,y) tuple

=item

--timefmt [format]

Interpret the X data as a time/date, parsed with the given format

=item

--colormap

Show a colormapped xy plot. Requires extra data for the color. zmin/zmax can be
used to set the extents of the colors. Automatically increments
C<--extraValuesPerPoint>

=item

--stream [period]

Plot the data as it comes in, in realtime. If period is given, replot every
period seconds. If no period is given, replot at 1Hz. If the period is given as
0 or 'trigger', replot I<only> when the incoming data dictates this. See the
L</"Real-time streaming data"> section of the man page.

=item

--[no]lines

Do [not] draw lines to connect consecutive points

=item

--[no]points

Do [not] draw points

=item

--circles

Plot with circles. This requires a radius be specified for each point.
Automatically increments C<--extraValuesPerPoint>). C<Not> supported for 3d
plots.

=item

--title xxx

Set the title of the plot

=item

--legend curveID legend

Set the label for a curve plot. Use this option multiple times for multiple
curves. With --dataid, curveID is the ID. Otherwise, it's the index of the
curve, starting at 0

=item

--autolegend

Use the curve IDs for the legend. Titles given with --legend override these

=item

--xlen xxx

When using --stream, sets the size of the x-window to plot. Omit this or set it
to 0 to plot ALL the data. Does not make sense with 3d plots. Implies
--monotonic

=item

--xmin/xmax/ymin/ymax/y2min/y2max/zmin/zmax xxx

Set the range for the given axis. These x-axis bounds are ignored in a streaming
plot. The y2-axis bound do not apply in 3d plots. The z-axis bounds apply
I<only> to 3d plots or colormaps.

=item

--xlabel/ylabel/y2label/zlabel xxx

Label the given axis. The y2-axis label does not apply to 3d plots while the
z-axis label applies I<only> to 3d plots.

=item

--y2 xxx

Plot the data specified by this curve ID on the y2 axis. Without --dataid, the
ID is just an ordered 0-based index. Does not apply to 3d plots. Can be passed
multiple times, or passed a comma-separated list. By default the y2-axis curves
look the same as the y-axis ones. I.e. the viewer of the resulting plot has to
be told which is which via an axes label, legend, etc. Prior to version 1.25 of
feedgnuplot the curves plotted on the y2 axis were drawn with a thicker line.
This is no longer the case, but that behavior can be brought back by passing
something like

 --y2 curveid --curvestyle curveid 'linewidth 3'

=item

--histogram curveID


Set up a this specific curve to plot a histogram. The bin width is given with
the --binwidth option (assumed 1.0 if omitted). --histogram does NOT touch the
drawing style. It is often desired to plot these with boxes, and this MUST be
explicitly requested with --curvestyleall 'with boxes'. This works with --domain
and/or --stream, but in those cases the x-value is used ONLY to cull old data
because of --xlen or --monotonic. I.e. the x-values are NOT drawn in any way.
Can be passed multiple times, or passed a comma- separated list

=item

--binwidth width

The width of bins when making histograms. This setting applies to ALL histograms
in the plot. Defaults to 1.0 if not given.

=item

--histstyle style

Normally, histograms are generated with the 'smooth freq' gnuplot style.
--histstyle can be used to select different 'smooth' settings. Allowed are
'unique', 'cumulative' and 'cnormal'. 'unique' indicates whether a bin has at
least one item in it: instead of counting the items, it'll always report 0 or 1.
'cumulative' is the integral of the "normal" histogram. 'cnormal' is like
'cumulative', but rescaled to end up at 1.0.

=item

--curvestyle curveID

style Additional styles per curve. With --dataid, curveID is the ID. Otherwise,
it's the index of the curve, starting at 0. Use this option multiple times for
multiple curves. --curvestylall does NOT apply to curves that have a
--curvestyle

=item

--curvestyleall xxx

Additional styles for all curves that have no --curvestyle

=item

--extracmds xxx

Additional commands. These could contain extra global styles for instance. Can
be passed multiple times.

=item

--square

Plot data with aspect ratio 1. For 3D plots, this controls the aspect ratio for
all 3 axes

=item

--square_xy

For 3D plots, set square aspect ratio for ONLY the x,y axes

=item

--hardcopy xxx

If not streaming, output to a file specified here. Format inferred from
filename, unless specified by --terminal

=item

--terminal xxx

String passed to 'set terminal'. No attempts are made to validate this.
--hardcopy sets this to some sensible defaults if --hardcopy is given .png,
.pdf, .ps, .eps or .svg. If any other file type is desired, use both --hardcopy
and --terminal

=item

--maxcurves xxx

The maximum allowed number of curves. This is 100 by default, but can be reset
with this option. This exists purely to prevent perl from allocating all of the
system's memory when reading bogus data

=item

--monotonic

If --domain is given, checks to make sure that the x- coordinate in the input
data is monotonically increasing. If a given x-variable is in the past, all data
currently cached for this curve is purged. Without --monotonic, all data is
kept. Does not make sense with 3d plots. No --monotonic by default. The data is
replotted before being purged

=item

--extraValuesPerPoint

xxx How many extra values are given for each data point. Normally this is 0, and
does not need to be specified, but sometimes we want extra data, like for colors
or point sizes or error bars, etc. feedgnuplot options that require this
(colormap, circles) automatically set it. This option is ONLY needed if unknown
styles are used, with --curvestyleall for instance

=item

--dump

Instead of printing to gnuplot, print to STDOUT. Very useful for debugging. It
is possible to send the output produced this way to gnuplot directly.

=item

--exit

Terminate the feedgnuplot process after passing data to gnuplot. The window will
persist but will not be interactive. Without this option feedgnuplot keeps
running and must be killed by the user. Note that this option works only with
later versions of gnuplot and only with some gnuplot terminals.

=item

--geometry

If using X11, specifies the size, position of the plot window

=item

--version

Print the version and exit

=back

=head1 RECIPES

=head2 Basic plotting of piped data

 $ seq 5 | awk '{print 2*$1, $1*$1}'
 2 1
 4 4
 6 9
 8 16
 10 25

 $ seq 5 | awk '{print 2*$1, $1*$1}' |
   feedgnuplot --lines --points --legend 0 "data 0" --title "Test plot" --y2 1

=head2 Realtime plot of network throughput

Looks at wlan0 on Linux.

 $ while true; do sleep 1; cat /proc/net/dev; done |
   gawk '/wlan0/ {if(b) {print $2-b; fflush()} b=$2}' |
   feedgnuplot --lines --stream --xlen 10 --ylabel 'Bytes/sec' --xlabel seconds

=head2 Realtime plot of battery charge in respect to time

Uses the result of the C<acpi> command.

 $ while true; do acpi; sleep 15; done |
   perl -nE 'BEGIN{ $| = 1; } /([0-9]*)%/; say join(" ", time(), $1);' |
   feedgnuplot --stream --ymin 0 --ymax 100 --lines --domain --xlabel 'Time' --timefmt '%s' --ylabel "Battery charge (%)"

=head2 Realtime plot of temperatures in an IBM Thinkpad

Uses C</proc/acpi/ibm/thermal>, which reports temperatures at various locations
in a Thinkpad.

 $ while true; do cat /proc/acpi/ibm/thermal | awk '{$1=""; print}' ; sleep 1; done |
   feedgnuplot --stream --xlen 100 --lines --autolegend --ymax 100 --ymin 20 --ylabel 'Temperature (deg C)'

=head2 Plotting a histogram of file sizes in a directory

 $ ls -l | awk '{print $5/1e6}' |
   feedgnuplot --histogram 0 --curvestyleall 'with boxes' --ymin 0 --xlabel 'File size (MB)' --ylabel Frequency

=head1 ACKNOWLEDGEMENT

This program is originally based on the driveGnuPlots.pl script from
Thanassis Tsiodras. It is available from his site at
L<http://users.softlab.ece.ntua.gr/~ttsiod/gnuplotStreaming.html>

=head1 REPOSITORY

L<https://github.com/dkogan/feedgnuplot>

=head1 AUTHOR

Dima Kogan, C<< <dima@secretsauce.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2012 Dima Kogan.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
