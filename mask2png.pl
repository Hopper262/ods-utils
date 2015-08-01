#!/usr/bin/perl
use strict;
use warnings 'FATAL' => 'all';
use Image::Magick ();
use FindBin ();
require "$FindBin::Bin/io.subs";

binmode STDIN;
binmode STDOUT;
use bytes;

my @colors = ( [ 1, 1, 1, 0 ], [ 0, 0, 0, 0 ] );

# mask resource:
#   10-byte header: file size, bounds rect
#   list of:
#     row number - terminated by 0x7fff
#     list of: on, off, etc. - terminated by 0x7fff

# While the mask is stored as a series of horizontal
# lines, those points actually define mask data for
# columns. So, we have to unpack the horizontal data
# and then use it to draw vertical masking sections.

# header
my $size = ReadUint16();
my ($top, $left, $bottom, $right) = (ReadSint16(), ReadSint16(), ReadSint16(), ReadSint16());

# build column data from row data
my @colspans = ();
while ($size > CurOffset())
{
  my $row = ReadUint16();
  last if $row == 32767;
  
#   warn "Examining row: $row\n";
  while (1)
  {
    my $start = ReadUint16();
    last if $start == 32767;
    my $end = ReadUint16();
    $end = $right if $end == 32767;
    
#     warn "Found pair: $start, $end\n";
    
    for my $col ($start..($end - 1))
    {
      $colspans[$col] = [] unless $colspans[$col];
      push(@{ $colspans[$col] }, $row);
    }
  }
}


# build image
my $width = $right + 1;
my $height = $bottom + 1;

my $img = Image::Magick->new();
$img->Set('size' => $width . 'x' . $height);
if (scalar @colspans)
{
  $img->Read('canvas:black');
}
else
{
$img->Read('canvas:white');  # empty masks are fully opaque
}

for my $col ($left..($right - 1))
{
  next unless $colspans[$col];
  my @cdata = @{ $colspans[$col] };
  while (scalar @cdata)
  {
    my $start = shift @cdata;
    my $end = shift @cdata;
    
    for my $row ($start..($end - 1))
    {
      $img->SetPixel('x' => $col, 'y' => $row, 'color' => [ 255, 255, 255 ]);
    }
  }
}

$img->Write('png:-');


