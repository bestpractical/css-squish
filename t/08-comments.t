#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 2;

use_ok("CSS::Squish");

my $expected_result = <<'EOT';

/* comment */

/* comment with * inside */

/* multiline
comment */

/*
 * shiny
 * multiline
 * comment
 */


/**
  * From t/css/08-comments.css: @import "01-basic-import.css";
  */

inside 01-basic-import.css

/** End of 01-basic-import.css */


/* endless
 * bad comment

EOT

my $result = CSS::Squish->concatenate('t/css/08-comments.css');

is($result, $expected_result, "Basic import");

