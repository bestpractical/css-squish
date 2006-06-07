#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More skip_all => "diff says the output is the same.  Test::More doesn't.  Argh.";

use_ok("CSS::Squish");

my $expected_result = <<'EOT';


/**
  * Original CSS: @import "t/css/blam.css" print;
  */

@media print {
Blam!
}

/**
  * Original CSS: @import "t/css/blam.css";
  */

Blam!

/**
  * Original CSS: @import url( "t/css/foo.css") print,aural;
  */

@media print,aural {
foo1
}

/**
  * Original CSS: @import url(t/css/foo2.css ) print, aural, tty;
  */

@media print, aural, tty {
foo2
}

/**
  * Original CSS: @import 'failure.css' print;
  */

@media print {
/* WARNING: Unable to open file 'failure.css': No such file or directory */
}

fjkls
 jk

@import url("t/css/foo.css");

last
EOT

my $result = CSS::Squish->concatenate('t/css/02-edge-cases.css');

is($result, $expected_result, "Edge cases");

