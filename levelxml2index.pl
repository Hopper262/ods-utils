#!/usr/bin/perl
use strict;
use warnings 'FATAL' => 'all';
use XML::Simple ();

my $usage = "Usage: $0 < levels.xml > index.html\n";
my $xml = XML::Simple::XMLin('-', 'KeyAttr' => [], 'ForceArray' => 1);
die $usage unless $xml;
our $levs = $xml->{'level'};
die $usage unless $levs;

my $html = <<END;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
                      "http://www.w3.org/TR/html4/loose.dtd">
<html lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<link rel="stylesheet" type="text/css" href="style.css">
<style type="text/css">
body {
  font-family: Courier, monospace;
  font-size: 14px;
  color: black;
  padding: 0;
  margin: 0;
}
#wrapper {
  margin: 0;
  padding: 0;
  min-height: 100%;
  position: relative;
}
#starter {
  height: 1px;
}
#background {
  position: absolute;
  left: 0;
  top: 0;
  width: 600px;
  height: 1350px;
  background: url('graphics2/soldier_large.png');
  background-repeat: no-repeat;
}
#accentmap {
  position: absolute;
  left: 0;
  bottom: 0;
  width: 250px;
  height: 340px;
  background: url('graphics2/accentmap.png');
  background-repeat: no-repeat;
}
.text {
  font-family: Courier, monospace;
  font-size: 16px;
  color: black;
}
#content {
  margin: 800px 20px 20px 200px;
  width: 600px;
}
h1 {
  font-family: Courier, monospace;
  font-size: 18px;
  text-align: center;
  padding: 0;
  margin: 0 0 20px;
}
.levelrow .map_item {
  position: relative;
  float: left;
  padding: 0;
  margin: 0 9px;
  width: 132px;
  height: 132px;
  text-align: center;
}
.levelrow {
  height: 160px;
}
#footer {
  position: relative;
  font-size: 12px;
}
#footer .credit {
  padding: 8px 8px 12px 260px;
  color: #41280D;
}
#footer .credit a:hover {
  text-decoration: underline !important;
}
</style>
<title>Bungie's Operation: Desert Storm - Annotated Maps</title>
</head>
<body><div id="wrapper">
<div id="background"></div>
<div id="accentmap"></div>
<div id="starter"></div>

<div class="text" style="position: absolute; left: 330px; top: 80px; width: 440px; height: 200px">
On Wednesday January 16, 1991 The United States of America and the allied countries initiated Operation: Desert Storm in response to Saddam Hussein's hostile occupation of Kuwait. The military offensive was designed to drive Iraq's troops from Kuwait and restore the Kuwaiti government to power.
</div>

<div style="position: absolute; left: 300px; top: 310px; width: 500px; height: 80px">
<div style="text-align: center"><a href="#content"><img src="graphics2/logo.png" alt="Operation: Desert Storm"></a></div>
<div style="text-align: right; padding-right: 12px">&copy; 1991 Bungie Software</div>
</div>

<div class="text" style="position: absolute; left: 480px; top: 480px; width: 300px; height: 220px">
This game does not attempt to justify or judge the results of Desert Storm. Rather, it models certain aspects of the military campaign and provides an exciting forum for exposure to today's current event.
</div>

<div id="content">
<h1>COMBAT ZONES:</h1>

END

for my $level (@$levs)
{
  my $idx = $level->{'index'};
  my $where = $level->{'world'}[0]{'where'}[0];
  my $mod = $idx % 4;
  
  $html .= <<END if $mod == 1;
<div class="levelrow">
END
  my $page = sprintf('level%02d.html', $idx);
  my $img = sprintf('levels/level%03dsm.png', $idx);
  my $pos = $mod == 0 ? 'br' : 'bl';
  $html .= <<END;
<a href="$page" class="map_item">
<img src="$img">
<div class="info_anchor $pos"><div><div>$where ($idx)</div></div></div>
</a>
END
  $html .= <<END if $mod == 0;
</div>
END
}

$html .= <<END;
</div>
<div id="footer">
<div class="credit">Site and maps by <a href="https://github.com/Hopper262">Hopper</a> - game content by <a href="http://www.bungie.net/">Bungie</a></div>
</div>
</div></body>
</html>
END
print $html;
