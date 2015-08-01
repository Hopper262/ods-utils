#!/usr/bin/perl
use strict;
use warnings 'FATAL' => 'all';
use Image::Magick ();


our %pmap_mask = (
  98 => 99,
  100 => 100,
  101 => 101,
  102 => 102,
  103 => 103,
  104 => 104,
  105 => 105,
  106 => 106,
  107 => 107,
  108 => 108,
  109 => 109,
  110 => 110,
  111 => 111,
  120 => 100,
  121 => 100,
  122 => 100,
  123 => 103,
  124 => 103,
  125 => 103,
  126 => 106,
  127 => 106,
  128 => 106,
  129 => 109,
  130 => 109,
  131 => 109,
  200 => 200,
  201 => 201,
  202 => 202, # 203?
  500 => 500,
  501 => 501,
  502 => 502,
  800 => 850,
  801 => 850,
  802 => 850,
  803 => 850,
  804 => 850,
  825 => 875,
  826 => 876,
  827 => 877,
  828 => 878,
  829 => 879,
  830 => 880,
  831 => 881,
  832 => 882,
  900 => 950,
  901 => 951,
  902 => 952,
  1100 => 1150,
  1101 => 1151,
  1102 => 1152,
  1103 => 1153,
  1104 => 1154,
  1105 => 1155,
  1106 => 1156,
  1107 => 1157,
  1108 => 1158,
  1109 => 1159,
  );

my %masks;
for my $mid (values %pmap_mask)
{
  next if $masks{$mid};
  my $mname = "mask_$mid.png";
  unless (-e $mname)
  {
    warn "No mask found for $mid\n";
    next;
  }
  my $img = Image::Magick->new();
  $img->Read($mname);
  $masks{$mid} = $img;
}

for my $pname (glob 'pmap_*.png')
{
  my $color = Image::Magick->new();
  $color->Read($pname);
  my $merged;
  
  my $pid = $pname;
  $pid =~ s/\D//g;
  my $mid = $pmap_mask{$pid};
  unless ($mid)
  {
    # warn "No mask information for pmap $pid\n";
    # tbd
    $merged = $color;
  }
  else
  {
    my $mask = $masks{$mid};
    $merged = Image::Magick->new();
    $merged->Set('size' => $color->Get('width') . 'x' . $color->Get('height'));
    $merged->ReadImage('xc:none');
    $merged->Composite('image' => $color, 'compose' => 'Copy', 'mask' => $mask);
  }
  
  $merged->Write("merged/$pid.png");
}

# my %mask_used = map { $pmap_mask{$_} => 1 } keys %pmap_mask;
# for my $mname (glob 'mask_*.png')
# {
#   my $mid = $mname;
#   $mid =~ s/\D//g;
#   my $found = $mask_used{$mid};
#   unless ($found)
#   {
#     warn "Unused mask $mid\n";
#   }
# }
  
