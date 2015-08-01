#!/usr/bin/perl
use strict;
use warnings 'FATAL' => 'all';
use Image::Magick ();
use XML::Simple ();

our $DRAW_MINES = 0;
our $DRAW_OTHER = 1;
our %IMAGE_CACHE;

my $usage = "Usage: $0 <ppat-dir> <out-dir> < <levels.xml>\n";
my ($ppat_dir, $out_dir) = @ARGV;
die $usage unless -e $ppat_dir;
die $usage unless $out_dir;
mkdir $out_dir;
my $xml = XML::Simple::XMLin('-', 'KeyAttr' => [], 'ForceArray' => 1);
die $usage unless $xml;
our $levs = $xml->{'level'};
die $usage unless $levs;

my @ppats;
for my $ppat_id (128..135)
{
  my $ppat = Image::Magick->new();
  $ppat->Read("$ppat_dir/ppat_$ppat_id.png");
  my $tiled = Image::Magick->new();
  $tiled->Set('size' => '1024x1024');
  $tiled->Read('xc:black');
  $tiled->Composite('image' => $ppat, 'compose' => 'Copy', 'tile' => 'True');
  
  $ppats[$ppat_id - 128] = $tiled;
}

my @scenery;
for my $pict_id (10001..10001)
{
  my $pict = Image::Magick->new();
  $pict->Read("$ARGV[0]/PICT_$pict_id.png");
  $scenery[$pict_id - 10000] = $pict;
}

for my $level (@$levs)
{
  my $idx = $level->{'index'};
  
  my $img = Image::Magick->new();
  $img->Set('size' => '1024x1024');
  $img->Read('xc:black');
  
  my $bg_id = 2 + int(($idx - 1) / 4);
  $bg_id = 7 if $idx == 20;
  $img->Composite('image' => $ppats[$bg_id], 'compose' => 'Copy');
  DrawFancyBorder($img, [ MungePath([0,0], [0,1024], [1024,1024], [1024,0]) ], 1);
  
  my @path;
  my $mask = Image::Magick->new();
  $mask->Set('size' => '1024x1024');
  $mask->Read('xc:black');
  if ($level->{'fielddef'})
  {
    for my $field (@{ $level->{'fielddef'} })
    {
      push(@path, [ $field->{'x'}, $field->{'y'} ]);
    }
    @path = MungePath(@path);
    my $pathstr = '';
    for my $pair (@path)
    {
      $pathstr .= ' ' . $pair->[0] . ',' . $pair->[1];
    }
    $mask->Draw('primitive' => 'polygon', 'fill' => 'white', 'channel' => 'All', 'points' => $pathstr);
    $img->Composite('image' => $ppats[1], 'compose' => 'Copy', 'mask' => $mask);
  }
  
  if ($level->{'gas'})
  {
    my @gas;
    for my $field (@{ $level->{'gas'} })
    {
      push(@gas, [ $field->{'x'}, $field->{'y'} ]);
    }
    @gas = MungePath(@gas);
    my $pathstr = '';
    for my $pair (@gas)
    {
      $pathstr .= ' ' . $pair->[0] . ',' . $pair->[1];
    }
    my $gmask = Image::Magick->new();
    $gmask->Set('size' => '1024x1024');
    $gmask->Read('xc:black');
    $gmask->Draw('primitive' => 'polygon', 'fill' => 'white', 'channel' => 'All', 'points' => $pathstr, 'mask' => $mask);
    $img->Composite('image' => $ppats[0], 'compose' => 'Copy', 'mask' => $gmask);
  }
  
  if ($DRAW_MINES && $level->{'mine'})
  {
    my $fatal = Image::Magick->new();
    $fatal->Set('size' => '1024x1024');
    $fatal->Read('xc:black');
    my $warning = Image::Magick->new();
    $warning->Set('size' => '1024x1024');
    $warning->Read('xc:black');
    for my $mine (@{ $level->{'mine'} })
    {
      my ($x, $y, $size) = ($mine->{'x'}, $mine->{'y'}, $mine->{'size'});
      
      my $fatal_rect = sprintf('%d,%d %d,%d',
                               $x, $y, $x + $size, $y + $size);
      $fatal->Draw('primitive' => 'rectangle', 'fill' => 'white', 'points' => $fatal_rect);
      
      my $warn_rect = sprintf('%d,%d %d,%d',
                              $x - 20, $y - 20,
                              $x + $size + 20, $y + $size + 20);
      $warning->Draw('primitive' => 'rectangle', 'fill' => 'white', 'points' => $warn_rect);
    }
    # remove areas outside field boundaries
    $fatal->Composite('image' => $mask, 'compose' => 'Darken');
    $warning->Composite('image' => $mask, 'compose' => 'Darken');
    # remove fatal areas from warning
    my $f2 = Image::Magick->new();
    $f2->Set('size' => '1024x1024');
    $f2->Read('xc:black');
    $f2->Composite('image' => $fatal, 'compose' => 'Copy');
    $f2->Negate();
    $warning->Composite('image' => $f2, 'compose' => 'Darken');
    
    # finally, draw fatal and warning areas
    my $red = Image::Magick->new();
    $red->Set('size' => '1024x1024');
    $red->Read('xc:red');
#     $img->Composite('image' => $red, 'compose' => 'Colorize', 'mask' => $fatal);
#     my $ylw = Image::Magick->new();
#     $ylw->Set('size' => '1024x1024');
#     $ylw->Read('xc:yellow');
#     $img->Composite('image' => $ylw, 'compose' => 'Colorize', 'mask' => $warning);
    $img->Composite('image' => $red, 'compose' => 'Dissolve', 'blend' => 50, 'mask' => $fatal);
    $img->Composite('image' => $red, 'compose' => 'Dissolve', 'blend' => 20, 'mask' => $warning);
  }      
  
  DrawFancyBorder($img, \@path, PathDir(\@path));
    
  if ($level->{'scenery'})
  {
    for my $item (@{ $level->{'scenery'} })
    {
      $img->Composite('image' => $scenery[$item->{'variant'}],
                      'compose' => 'Copy',
                      'x' => $item->{'x'},
                      'y' => $item->{'y'});
    }
  }
  
  if ($DRAW_OTHER)
  {
    if ($level->{'base'})
    {
      my $bidx = 0;
      for my $b (@{ $level->{'base'} })
      {
        $img->Composite('image' => CachedImage(1000 + $b->{'variant'}),
                        'compose' => 'Atop',
                        'x' => $b->{'x'}, 'y' => $b->{'y'});
        $bidx++;
      }
    }
  
    if ($level->{'gun'})
    {
      for my $b (@{ $level->{'gun'} })
      {
        $img->Composite('image' => CachedImage(800 + $b->{'variant'}),
                        'compose' => 'Atop',
                        'x' => $b->{'x'}, 'y' => $b->{'y'});
      }
    }
    if ($level->{'ngun'})
    {
      for my $b (@{ $level->{'ngun'} })
      {
        $img->Composite('image' => CachedImage(825 + $b->{'variant'}),
                        'compose' => 'Atop',
                        'x' => $b->{'x'}, 'y' => $b->{'y'});
      }
    }
    if ($level->{'vscene'})
    {
      for my $b (@{ $level->{'vscene'} })
      {
        $img->Composite('image' => CachedImage(1100 + $b->{'variant'}),
                        'compose' => 'Atop',
                        'x' => $b->{'x'}, 'y' => $b->{'y'});
      }
    }
    if ($level->{'target'})
    {
      for my $b (@{ $level->{'target'} })
      {
        next unless $b->{'x'} > 0 || $b->{'y'} > 0;
        $img->Composite('image' => CachedImage(600 + $b->{'variant'}),
                        'compose' => 'Atop',
                        'x' => $b->{'x'}, 'y' => $b->{'y'});
      }
    }
  }

  my $extra = '';
  $extra .= 'm' if $DRAW_MINES;
  $extra .= 'c' if $DRAW_OTHER;
  $img->Write(sprintf('png:%s/level%03d%s.png', $out_dir, $idx, $extra));
}


sub PathDir
{
  my ($path) = @_;
  
  my $sum = 0;
  my $len = scalar @$path;
  for my $i (0..($len - 1))
  {
    my $j = ($i + 1) % $len;
    $sum += ($path->[$j][0] - $path->[$i][0]) *
            ($path->[$j][1] + $path->[$i][1]);
  }
  return $sum < 0 ? 1 : -1;
}

sub MungePath
{
  my (@pathitems) = @_;

  my $path = \@pathitems;
  my $pathlen = scalar @pathitems;
  my @fullpath;
  
  for my $i (0..($pathlen - 1))
  {
    my $pt = $path->[$i];
    my $prev = ($i == 0) ? $path->[$pathlen - 1] : $path->[$i - 1];
    my $next = ($i == $pathlen - 1) ? $path->[0] : $path->[$i + 1];
    
    my $xd = 0;
    my $yd = 0;
    if ($prev->[0] < $pt->[0])
    {
      $yd = 1;
    }
    elsif ($prev->[0] > $pt->[0])
    {
      $yd = -1;
    }
    elsif ($prev->[1] < $pt->[1])
    {
      $xd = -1;
    }
    elsif ($prev->[1] > $pt->[1])
    {
      $xd = 1;
    }
    
    if ($pt->[0] < $next->[0])
    {
      $yd = 1;
    }
    elsif ($pt->[0] > $next->[0])
    {
      $yd = -1;
    }
    elsif ($pt->[1] < $next->[1])
    {
      $xd = -1;
    }
    elsif ($pt->[1] > $next->[1])
    {
      $xd = 1;
    }
    
    my ($x, $y) = ($pt->[0], $pt->[1]);
    $x-- if $xd > 0;
    $y-- if $yd > 0;
    push(@fullpath, [ $x, $y, $xd, $yd ]);
  }
  
  return @fullpath;
}

sub DrawFancyBorder
{
  my ($img, $path, $dir) = @_;
  
  my @fullpath = @$path;
  push(@fullpath, $fullpath[0]);

  for my $offset (1..5)
  {
    my $color = 'black';
    $color = 'white' if $offset == 2 || $offset == 3;
    
    $offset -= 1 if $dir > 0;
    
    my $lastpt;
    for my $pt (@fullpath)
    {
      unless ($lastpt)
      {
        $lastpt = $pt;
        next;
      }
      
      my $pathstr = sprintf('%d,%d %d,%d',
                            $lastpt->[0] - ($offset * $lastpt->[2] * $dir),
                            $lastpt->[1] - ($offset * $lastpt->[3] * $dir),
                            $pt->[0] - ($offset * $pt->[2] * $dir),
                            $pt->[1] - ($offset * $pt->[3] * $dir),
                            );
      
      $img->Draw('primitive' => 'rectangle', 'fill' => $color, 'points' => $pathstr);
      
      $lastpt = $pt;
    }
  }
} # end DrawFancyBorder

sub CachedImage
{
  my ($id) = @_;
  
  unless ($IMAGE_CACHE{$id})
  {
    my $img = Image::Magick->new();
    $img->Read("graphics/$id.png");
    $IMAGE_CACHE{$id} = $img;
  }
  return $IMAGE_CACHE{$id};
}
  
