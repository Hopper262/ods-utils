#!/usr/bin/perl
use strict;
use warnings 'FATAL' => 'all';
use XML::Simple ();

my $usage = "Usage: $0 <out-dir> < <levels.xml>\n";
my ($out_dir) = @ARGV;
die $usage unless $out_dir;
mkdir $out_dir;
my $xml = XML::Simple::XMLin('-', 'KeyAttr' => [], 'ForceArray' => 1);
die $usage unless $xml;
our $levs = $xml->{'level'};
die $usage unless $levs;

for my $level (@$levs)
{
  my $idx = $level->{'index'};
  my $where = $level->{'world'}[0]{'where'}[0];
  my @what = split('~', $level->{'world'}[0]{'what'}[0]);
  push(@what, '', '', '');
  
  my $html = <<END;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
                      "http://www.w3.org/TR/html4/loose.dtd">
<html lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<link rel="stylesheet" type="text/css" href="style.css">
<title>$where ($idx)</title>
</head>
<body>
<div id="nav"><div id="navinner">
END
  for my $i (1..20)
  {
    if ($i == $idx)
    {
      $html .= <<END;
<span class="button map_item">
<div class="label">$i</div>
<div class="info_anchor bl"><div><div>$where ($i)</div></div></div>
</span>
END
    }
    else
    {
      my $link = sprintf('level%02d.html', $i);
      my $title = $levs->[$i-1]{'world'}[0]{'where'}[0];
      $html .= <<END;
<a href="$link" class="button map_item">
<div class="label">$i</div>
<div class="info_anchor bl"><div><div>$title ($i)</div></div></div>
</a>
END
    }
  }
  $html .= <<END;
<a href="./" class="main"><img src="graphics2/logo_small.png" alt="Bungie's Operation: Desert Storm - Annotated Maps"></a>
</div></div>
<div id="content">
<div id="upper">
<div id="leftcol">
<img src="levels/level@{[ sprintf('%03d', $idx) ]}sm.png">
</div>
<div id="midcol">
<div id="briefing">
<h1>COMBAT ZONE: $where ($idx)</h1>
<div class="recon">
<div>$what[0] </div>
<div>$what[1] </div>
<div>$what[2] </div>
</div>
END
  my @rinf;
  for my $i (qw(dropoff pickup))
  {
    my $w = $level->{'transport'}[0]{$i}[0];
    my $inf = sprintf('%02d:%02d, [%02d-%02d]',
                      $w->{'time_h'}, $w->{'time_m'},
                      int($w->{'x'} / 100), int($w->{'y'} / 100));
    push(@rinf, $inf);
  }
  $html .= <<END;
<div class="release">
<div>RELEASE: $rinf[0]   EXTRACTION: $rinf[1]</div>
</div>
</div>
</div>
<div id="rightcol">
END

  my $hazard = '';
  my $off = 0;
  if ($level->{'mine'})
  {
    my $num = scalar @{ $level->{'mine'} };
    $hazard .= MapItem($off, 4, 'mine', 'Land Mine', $num . 'x Mine');
    $off += 60;
  }
  if ($level->{'gas'})
  {
    $hazard .= MapItem($off, 4, 'gas', 'Chemical Weapons');
    $off += 60;
  }
  if ($level->{'flyer'})
  {
    my %names = ( '900' => 'Mi-24 Hind',
                  '901' => 'MiG-29 Fulcrum',
                  '902' => 'Mirage F-1',
                );
    my %offsets = ( '900' => 2, '901' => 10, '902' => 12 );
    my (%byvar, %bytime, %pts);
    for my $b (@{ $level->{'flyer'} })
    {
      my $var = 900 + $b->{'variant'};
      $pts{$var} = $b->{'score'};
      my $detail = sprintf('<div>%02d:%02d - %02d:%02d</div>',
                           $b->{'start_h'}, $b->{'start_m'},
                           $b->{'end_h'}, $b->{'end_m'});
      $byvar{$var} = [] unless $byvar{$var};
      push(@{ $byvar{$var} }, $detail);
      $bytime{$detail} = $var;
    }
    my %seen;
    for my $det (sort keys %bytime)
    {
      my $var = $bytime{$det};
      next if $seen{$var};
      $seen{$var} = 1;
      
      $hazard .= MapItem($off, $offsets{$var}, $var,
                         'Hostile Aircraft',
                         sprintf('<div>%dx %s (%d pts.)</div>',
                                 scalar(@{ $byvar{$var} }),
                                 $names{$var},
                                 $pts{$var}),
                         sort @{ $byvar{$var} });
      $off += 60;
    }
  }
  if ($hazard)
  {
    $hazard =~ s/info_anchor bl/info_anchor br/g;
    $html .= <<END;
<div id="hazards">$hazard</div>
END
  }
  
  my $army = '';
  $off = 0;
  if ($level->{'gun'})
  {
    my $num = scalar @{ $level->{'gun'} };
    $army .= MapItem($off + 1, 0, 800, 'Gunner Station',
                     $num . 'x Multidirectional (150 pts.)');
    $off += 40;
  }
  if ($level->{'ngun'})
  {
    my $num = scalar @{ $level->{'ngun'} };
    $army .= MapItem($off + 1, 5, 827, 'Gunner Station',
                     $num . 'x G-5 Howitzer (75 pts.)');
    $off += 40;
  }
  if ($level->{'army'})
  {
    my @amts = (0, 0, 0);
    my @names = ('T-55 (75 pts.)', 'T-62 (150 pts.)', 'T-72 (300 pts.)');
    for my $b (@{ $level->{'army'} })
    {
      $amts[$b->{'variant'} - 1]++;
    }
    for my $var (0..2)
    {
      next unless $amts[$var] > 0;
      $army .= MapItem($off + 3, 1, 120 + $var, 'Enemy Tank',
                       $amts[$var] . 'x ' . $names[$var]);
      $off += 40;
    }
  }
  if ($army)
  {
    $army =~ s/info_anchor bl/info_anchor br/g;
    $html .= <<END;
<div id="armies">$army</div>
END
  }
  
  if ($level->{'target'})
  {
    my %tinfo;
    for my $b (@{ $level->{'target'} })
    {
      my $pos = ($b->{'x'} == 0 && $b->{'y'} == 0) ? 'random' : 'fixed';
      $tinfo{$b->{'variant'}}{$pos}{$b->{'amount'}}++;
    }
    
    my @target_names = ('Fuel',
                        'Missile',
                        'Asset (50 pts.)',
                        'POW (75 pts.)');
    my $target = '';
    my $off = 0;
    for my $var (sort keys %tinfo)
    {
      my $all_det = '';
      for my $pos (reverse sort keys %{ $tinfo{$var} })
      {
        for my $amt (sort { $b <=> $a } keys %{ $tinfo{$var}{$pos} })
        {
          $all_det .= '<div>' . $tinfo{$var}{$pos}{$amt} .
                      'x ' . $pos;
          $all_det .= ' (+' . $amt . ')' if $amt;
          $all_det .= '</div>';
        }
      }
      $target .= MapItem($off, 0, (600 + $var) . 'm',
                         'Prize Item',
                         '<div>' . $target_names[$var] . '</div>',
                         $all_det);
      $off += 40;
    }
    $target =~ s/info_anchor bl/info_anchor tr/g;
    $html .= <<END;
<div id="prizes">$target</div>
END
  }

  if ($level->{'vscene'})
  {
    my @names = ('Nuclear Facility',
                 'Chemical Plant',
                 'Oil Reserves',
                 'Weapons Depot',
                 'Command &amp; Control',
                 'SCUD Launcher',
                 'Army Bunker',
                 'Iraqi Army HQ');
    my @amts = (0) x scalar @names;
    for my $b (@{ $level->{'vscene'} })
    {
      $amts[$b->{'variant'}]++;
    }
    my @all_det;
    my $first_var = -1;
    for my $var (0..(scalar(@names) - 1))
    {
      next unless $amts[$var] > 0;
      $first_var = $var if $first_var < 0;
      push(@all_det, '<div>' . $amts[$var] . 'x ' .
                      $names[$var] . ' (500 pts.)</div>');
    }
    my $vscene = MapItem(0, 0, 1100 + $first_var, 
                         'Strategic Target', @all_det, '');
    $vscene =~ s/info_anchor bl/info_anchor tr/g;
    $vscene =~ s/left: 0px; top: 0px/right: 0px; bottom: 0px/;
    $html .= <<END;
<div id="targets">$vscene</div>
END
  }  

  
  $html .= <<END;
</div>
<div id="post_upper"></div></div>
<div id="map_legend">
<div class="legend top">
  <div class="coord even" style="left: 1px; width: 98px">00</div>
  <div class="coord odd" style="left: 100px">01</div>
  <div class="coord even" style="left: 200px">02</div>
  <div class="coord odd" style="left: 300px">03</div>
  <div class="coord even" style="left: 400px">04</div>
  <div class="coord odd" style="left: 500px">05</div>
  <div class="coord even" style="left: 600px">06</div>
  <div class="coord odd" style="left: 700px">07</div>
  <div class="coord even" style="left: 800px">08</div>
  <div class="coord odd" style="left: 900px">09</div>
  <div class="coord even" style="left: 1000px; width: 23px"></div>
</div>
<div class="legend left">
  <div class="coord even" style="top: 1px; height: 98px; line-height: 98px">00</div>
  <div class="coord odd" style="top: 100px">01</div>
  <div class="coord even" style="top: 200px">02</div>
  <div class="coord odd" style="top: 300px">03</div>
  <div class="coord even" style="top: 400px">04</div>
  <div class="coord odd" style="top: 500px">05</div>
  <div class="coord even" style="top: 600px">06</div>
  <div class="coord odd" style="top: 700px">07</div>
  <div class="coord even" style="top: 800px">08</div>
  <div class="coord odd" style="top: 900px">09</div>
  <div class="coord even" style="top: 1000px; height: 23px; line-height: 23px"></div>
</div>

<div class="map">
<img id="map_bg" src="levels/level@{[ sprintf('%03d', $idx) ]}m.png" width="1024" height="1024">

END

#   if ($level->{'mine'})
#   {
#     for my $b (@{ $level->{'mine'} })
#     {
#       my $size = $b->{'radius'};
#       my $x = $b->{'x'};
#       my $y = $b->{'y'};
#       my $xoff = int($size / 2) - 18;
#       my $yoff = int($size / 2) - 14;
#       my $left = $x + $xoff;
#       my $top = $y + $yoff;
#       $yoff += 20;
#       $xoff += 20;
#       $html .= <<END;
# <div class="map_item mine" style="left: ${left}px; top: ${top}px;">
# <div class="mine_radius" style="height: ${size}px; width: ${size}px; left: -${xoff}px; top: -${yoff}px"></div>
# <img src="graphics/701.png" class="mine_pic">
# <div class="info_anchor tl"><div>
# <div>Land Mine</div>
# </div></div></div>
# END
#     }
#   }
  if ($level->{'transport'})
  {
    my $dropoff = $level->{'transport'}[0]{'dropoff'}[0];
    my $pickup = $level->{'transport'}[0]{'pickup'}[0];
    my $carrier = $level->{'transport'}[0]{'carrier'}[0];
    
    $html .= MapItem($dropoff->{'x'}, $dropoff->{'y'},
                     'release_' . (50 + $carrier->{'dropoff_variant'}),
                     'Release',
                     sprintf('%02d:%02d',
                             $dropoff->{'time_h'}, $dropoff->{'time_m'}));
    $html .= MapItem($pickup->{'x'}, $pickup->{'y'},
                     50 + $carrier->{'pickup_variant'},
                     'Extraction',
                     sprintf('%02d:%02d',
                             $pickup->{'time_h'}, $pickup->{'time_m'}));
  }
  
  if ($level->{'base'})
  {
    my $bidx = 0;
    for my $b (@{ $level->{'base'} })
    {
      $html .= MapItem($b->{'x'}, $b->{'y'},
                       1000 + $b->{'variant'},
                       'Enemy Base',
                       TankInfo($bidx, $level->{'army'}));
      $bidx++;
    }
  }

  if ($level->{'gun'})
  {
    for my $b (@{ $level->{'gun'} })
    {
      $html .= MapItem($b->{'x'}, $b->{'y'},
                       800 + $b->{'variant'},
                       'Gunner Station',
                       'Multidirectional (' . $b->{'score'} . ' pts.)');
    }
  }
  if ($level->{'ngun'})
  {
    for my $b (@{ $level->{'ngun'} })
    {
      $html .= MapItem($b->{'x'}, $b->{'y'},
                       825 + $b->{'variant'},
                       'Gunner Station',
                       'G-5 Howitzer (' . $b->{'score'} . ' pts.)');
    }
  }
  if ($level->{'vscene'})
  {
    my @vscene_names = ('Nuclear Facility',
                        'Chemical Plant',
                        'Oil Reserves',
                        'Weapons Depot',
                        'Command &amp; Control',
                        'SCUD Launcher',
                        'Army Bunker',
                        'Iraqi Army HQ');
    
    for my $b (@{ $level->{'vscene'} })
    {
      $html .= MapItem($b->{'x'}, $b->{'y'},
                       1100 + $b->{'variant'},
                       'Strategic Target',
                       $vscene_names[$b->{'variant'}] . ' (500 pts.)');
    }
  }
  if ($level->{'target'})
  {
    my @target_names = ('Fuel',
                        'Missile',
                        'Asset (50 pts.)',
                        'POW (75 pts.)');
    
    for my $b (@{ $level->{'target'} })
    {
      next unless $b->{'x'} > 0 || $b->{'y'} > 0;
      my $name = $target_names[$b->{'variant'}];
      $name .= ' (+' . $b->{'amount'} . ')' if $b->{'amount'} > 0;
      $html .= MapItem($b->{'x'}, $b->{'y'},
                       600 + $b->{'variant'},
                       'Prize Item',
                       $name);
    }
  }

  $html .= <<END;
</div>
</div>
</body>
</html>
END

  my $fh;
  open($fh, '>', "$out_dir/level" . sprintf('%02d', $idx) . '.html') or die $!;
  print $fh $html;
  close $fh;
}

sub TankInfo
{
  my ($base, $army) = @_;
  return () unless $army;
  
  my @tank_names = qw(Unused T-55 T-62 T-72);
  
  my @content;
  for my $a (@$army)
  {
    next unless $a->{'base'} == $base;
    my $img = $a->{'variant'} + 119;
    my $pt = $a->{'score'};
    my $name = $tank_names[$a->{'variant'}];
    push(@content, <<END);
<div class="tankline"><img src="graphics/$img.png"> $name ($pt pts.)</div>
END
  }
  return @content;
}

sub MapItem
{
  my ($left, $top, $img, $title, @content) = @_;
  
  my $pos = ($top >= 150 ? 't' : 'b') . ($left >= 800 ? 'r' : 'l');
  my $sub = '';
  if (scalar(@content) > 1)
  {
    $sub .= join('', @content);
  }
  elsif (scalar(@content) > 0)
  {
    $sub = '<div>' . $content[0] . '</div>';
  }
  
  my $imgpath = $img =~ /^\d+$/ ? "graphics/$img.png" : "graphics2/$img.png";
  return <<END;
<div class="map_item" style="left: ${left}px; top: ${top}px">
<img src="$imgpath">
<div class="info_anchor $pos"><div>
<div>$title</div>
$sub
</div></div></div>
END
}
