#!/usr/bin/perl
  use lib '/Users/woo/Development/Forth/Perl/PDL-2.4.11/blib/lib';
  use lib '/Users/woo/Development/Forth/Perl/PDL-2.4.11/blib/lib/PDL';
  use PDL;
  use PDL::Graphics::LUT;
  use PDL::Graphics::AquaTerm;
  my $x_size = 255; my $y_size = 255;
  aquaOpen({SIZE_X => $x_size, SIZE_Y => $y_size});
  aquaSetColorTable(cat(lut_data('idl5')));
  my $a = xvals(zeroes(byte,$x_size,$y_size));
  aquaBitmap($a);
