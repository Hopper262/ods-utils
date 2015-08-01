ods-utils
=========

These Perl scripts were used to read data from Bungie Software's 1991 game _Operation: Desert Storm_, and create the content for my [ODS Annotated Maps](http://www.whpress.com/ods/) site.

These are all command-line tools. Usually the input is expected on stdin and output is written to stdout.

### bmap2png.pl, pmap2png.pl, mask2png.pl

These convert `bmap`, `pmap`, `clut`, and `mask` resource data into PNG graphics. My "classic-mac-utils" repository contains scripts for extracting resource data from the application.

### build_gfx.pl

This combines a set of pmap and mask PNGs into new PNGs with an alpha channel. ODS hardcoded which masks go with which pmaps; this script uses a reverse-engineered list.

### level2xml.pl

The "Logistics" file in ODS is actually a fairly readable plain text file (with Mac line endings, naturally). However, I wanted something a little better documented and easily parsed for the subsequent steps, so this script produces more verbose XML.

### levelxml2png.pl

This draws the field for each level. Recreating the border-drawing logic was fun.

### levelxml2html.pl, levelxml2index.pl

These two scripts produced all the HTML for the Annotated Maps site.
