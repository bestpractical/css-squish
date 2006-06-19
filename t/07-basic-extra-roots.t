#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 2;
use Test::LongString;

use_ok("CSS::Squish");

my $expected_result = <<'EOT';


/**
  * From t/css/07-basic-extra-roots.css: @import "07-basic-extra-roots2.css";
  */

foobar

/** End of 07-basic-extra-roots2.css */

blam

EOT

CSS::Squish->roots( 't/css2/' );
my $result = CSS::Squish->concatenate('t/css/07-basic-extra-roots.css');

is_string($result, $expected_result, "Basic extra roots");

