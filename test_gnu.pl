#!/usr/bin/perl
#
# This is how the graphics package will write out the x and y arrays
  my  @x  = ( -2, -1.50, -1, -0.50,  0,  0.50,  1, 1.50, 2 ); # x values
  my  @y1 = (  4,  2.25,  1,  0.25,  0,  0.25,  1, 2.25, 4 ); # function 1
  my  @y2 = (  2,  0.25, -1, -1.75, -2, -1.75, -1, 0.25, 2 ); # function 2
$data_file = "myplot";
# This is the $data_file.  We can either fill it OR set it to point to a particular external file
open (DATA, ">$data_file.dat");
while( $#x )
{
	$xval = shift(@x);
	$y1val = shift(@y1);
	$y2val = shift(@y2);
	print DATA " $xval $y1val $y2val\n";
}
close(DATA);
#
# So that the data is in the $data_file properly for plotting.
#
$xlabel = "x-label";
$ylabel = "y-label";
$title = "X/Y Plot";
$xlabel_font = "Courier,14";
$ylabel_font = "Courier,10";
$title_font = "HelveticaBold,18";
$xsize = 1;
$ysize = 1;
$plt_str = "\"$data_file\" using 1:2 with lines";
$plt_str = "sin(x)/x";
$scaling = "set autoscale";
$xtics = 10;
$grid = "set grid xtics ytics";
$key = "set nokey";
# Store all above values in forth variables
# The below becomes the -plot function
# In the graphics package, plot will provide taking the data from x and y as above
# and writing it to the $data_file, then calling _plot function.
#
open (GNUPLOT, "|gnuplot");
print GNUPLOT <<EOPLOT;
set term post color "Courier" 12
set output "$data_file.ps"
set size $xsize ,$ysize
$key
$scaling
set xlabel "$xlabel" font "xlabel_font"
set ylabel "$ylabel" font "$ylabel_font"
set title "$title" font "$title_font"
$grid
set xtics $xtics
plot $plt_str
EOPLOT

close(GNUPLOT);
system ("open","$data_file.ps");
