#!/usr/bin/perl
use strict;
use warnings 'FATAL' => 'all';
use Parse::RecDescent ();
use XML::Writer ();

my $levelset;
do {
  local $/ = undef;
  $levelset = <STDIN>;
};
die "No levels\n" unless $levelset;

my $parser = Parse::RecDescent->new(<<'END');
<autoaction: $item[2] >
{ use XML::Writer ();
  my $outstr = '';
  my $out = XML::Writer->new('OUTPUT' => \$outstr,
                             'DATA_MODE' => 1,
                             'DATA_INDENT' => '  ',
                             'ENCODING' => 'us-ascii');
}

levels: 
  { $out->startTag($item[0]); $out; }
  level(s)
  { $out->endTag($item[0]); $out->end(); $outstr; }

level: 'LEVEL' paren1
  { $out->startTag($item[0], 'index' => $item[2]); $out; }
  world transport
  fielddef mine gun ngun base army
  gas flyer scenery vscene target
  'END'
  { $out->endTag($item[0]); $out; }

world: 'WORLD'
  { $out->startTag($item[0]); $out; }
  loc where what
  { $out->endTag($item[0]); $out; }
loc: 'LOC' paren2
  { $out->emptyTag($item[0],
                   'x' => $item[2][0],
                   'y' => $item[2][1]); $out; }
where: 'WHERE' parenstr
  { $out->dataElement($item[0], $item[2]); $out; }
what: 'WHAT' parenstr
  { $out->dataElement($item[0], $item[2]); $out; }
       
transport: 'TRANSPORT'
  { $out->startTag($item[0]); }
  disp carrier dropoff pickup
  { $out->endTag($item[0]); }
disp: 'DISP' paren2
  { $out->emptyTag($item[0], 
                   'x' => $item[2][0],
                   'y' => $item[2][1]); $out; }
carrier: 'CARRIER' paren2
  { $out->emptyTag($item[0],
                   'dropoff_variant' => $item[2][0],
                   'pickup_variant' => $item[2][1]); $out; }
dropoff: 'DROPOFF' paren4
  { $out->emptyTag($item[0],
                   'time_h' => $item[2][0],
                   'time_m' => $item[2][1],
                   'x' => $item[2][2],
                   'y' => $item[2][3]); $out; }
pickup: 'PICKUP' paren4
  { $out->emptyTag($item[0],
                   'time_h' => $item[2][0],
                   'time_m' => $item[2][1],
                   'x' => $item[2][2],
                   'y' => $item[2][3]); $out; }

fielddef: 'FIELDDEF' paren1 paren2(s)
  { for my $i (0..($item[2]-1))
    {
      my $ref = $item[3][$i];
      $out->emptyTag($item[0],
                     'x' => $ref->[0],
                     'y' => $ref->[1],
                     );
    }
    1; }
mine: 'MINE' paren1 paren3(s?)
  { for my $i (0..($item[2]-1))
    {
      my $ref = $item[3][$i];
      $out->emptyTag($item[0],
                     'x' => $ref->[0],
                     'y' => $ref->[1],
                     'size' => $ref->[2],
                     );
    }
    1; }
gun: 'GUN' paren1 paren4(s?)
  { for my $i (0..($item[2]-1))
    {
      my $ref = $item[3][$i];
      $out->emptyTag($item[0],
                     'x' => $ref->[0],
                     'y' => $ref->[1],
                     'score' => $ref->[2],
                     'variant' => $ref->[3],
                     );
    }
    1; }
ngun: 'NGUN' paren1 paren6(s?)
  { for my $i (0..($item[2]-1))
    {
      my $ref = $item[3][$i];
      $out->emptyTag($item[0],
                     'x' => $ref->[0],
                     'y' => $ref->[1],
                     'score' => $ref->[2],
                     'variant' => $ref->[3],
                     'aim_x' => $ref->[4],
                     'aim_y' => $ref->[5],
                     );
    }
    1; }
base: 'BASE' paren1 paren3(s?)
  { for my $i (0..($item[2]-1))
    {
      my $ref = $item[3][$i];
      $out->emptyTag($item[0],
                     'x' => $ref->[0],
                     'y' => $ref->[1],
                     'variant' => $ref->[2],
                     );
    }
    1; }
army: 'ARMY' paren1 paren3(s?)
  { for my $i (0..($item[2]-1))
    {
      my $ref = $item[3][$i];
      $out->emptyTag($item[0],
                     'base' => $ref->[0],
                     'variant' => $ref->[1],
                     'score' => $ref->[2],
                     );
    }
    1; }
gas: 'GAS' paren1 paren2(s?)
  { for my $i (0..($item[2]-1))
    {
      my $ref = $item[3][$i];
      $out->emptyTag($item[0],
                     'x' => $ref->[0],
                     'y' => $ref->[1],
                     );
    }
    1; }
flyer: 'FLYER' paren1 paren6(s?)
  { for my $i (0..($item[2]-1))
    {
      my $ref = $item[3][$i];
      $out->emptyTag($item[0],
                     'variant' => $ref->[0],
                     'score' => $ref->[1],
                     'start_h' => $ref->[2],
                     'start_m' => $ref->[3],
                     'end_h' => $ref->[4],
                     'end_m' => $ref->[5],
                     );
    }
    1; }
scenery: 'SCENERY' paren1 paren3(s?)
  { for my $i (0..($item[2]-1))
    {
      my $ref = $item[3][$i];
      $out->emptyTag($item[0],
                     'variant' => $ref->[0],
                     'x' => $ref->[1],
                     'y' => $ref->[2],
                     );
    }
    1; }
vscene: 'VSCENE' paren1 paren3(s?)
  { for my $i (0..($item[2]-1))
    {
      my $ref = $item[3][$i];
      $out->emptyTag($item[0],
                     'variant' => $ref->[0],
                     'x' => $ref->[1],
                     'y' => $ref->[2],
                     );
    }
    1; }
target: 'TARGET' paren1 paren4(s?)
  { for my $i (0..($item[2]-1))
    {
      my $ref = $item[3][$i];
      $out->emptyTag($item[0],
                     'variant' => $ref->[0],
                     'x' => $ref->[1],
                     'y' => $ref->[2],
                     'amount' => $ref->[3],
                     );
    }
    1; }


str: '"' /[^"]*/ '"'
parenstr: '(' str ')'

num: /\d+/
  { $item[1] + 0 }
paren1: '(' num ')'
paren2: '(' num(2 /,/) ')'
paren3: '(' num(3 /,/) ')'
paren4: '(' num(4 /,/) ')'
paren5: '(' num(5 /,/) ')'
paren6: '(' num(6 /,/) ')'
END


my $result = $parser->levels($levelset);
die "Parse failed" unless defined $result;
print $result;
