use strict;
use warnings;

package CSS::Squish;

$CSS::Squish::VERSION = '0.01';

use File::Spec;

=head1 NAME

CSS::Squish - Compact many CSS files into one big file

=head1 SYNOPSIS

 use CSS::Squish;
 my $concatenated = CSS::Squish->concatenate(@files);

=head1 DESCRIPTION

This module takes a list of CSS files and concatenates them, making sure
to honor any valid @import statements included in the files.

Following the CSS 2.1 spec, @import statements must be the first rules in
a CSS file.  Media-specific @import statements will be honored by enclosing
the included file in an @media rule.  This has the side effect of actually
I<improving> compatibility in Internet Explorer, which ignores
media-specific @import rules but understands @media rules.

It is possible that feature versions will include methods to compact
whitespace and other parts of the CSS itself, but this functionality
is not supported at the current time.

=cut

#
# This should be a decently close CSS 2.1 compliant parser for @import rules
#
# XXX TODO: This does NOT deal with comments at all at the moment.  Which
# is sort of a problem.
# 

my @MEDIA_TYPES = qw(all aural braille embossed handheld print
                     projection screen tty tv);
my $MEDIA_TYPES = '(?:' . join('|', @MEDIA_TYPES) . ')';
my $MEDIA_LIST  = qr/(?:$MEDIA_TYPES,\s*)*?$MEDIA_TYPES/;

my $AT_IMPORT = qr/^\s*                     # leading whitespace
                    \@import\s+             # @import
                        (?:url\(            #   url(
                        \s*                 #   optional whitespace
                        (?:"|')?            #   optional " or '
                      |                     # or
                        (?:"|'))            #   " or '
                      (.+?)                 # the filename
                        (?:(?:"|')?         #   optional " or '
                        \s*                 #   optional whitespace
                        \)                  #   )
                      |                     # or
                        (?:"|'))            #   " or '
                    (?:\s($MEDIA_LIST))?    # the optional media list
                    \;                      # finishing semi-colon
                   \s*$                     # trailing whitespace
                  /x;

=head1 METHODS

=head2 B<CSS::Squish-E<gt>concatenate(@files)>

Takes a list of files to concatenate and returns the results as one big scalar.

=head2 B<CSS::Squish-E<gt>concatenate_to($dest, @files)>

Takes a filehandle to print to and a list of files to concatenate.
C<concatenate> uses this method with an C<open>ed scalar.

=cut

sub concatenate {
    my $self   = shift;
    my $string = '';
    
    open my $fh, '>', \$string or die "Can't open scalar as file! $!";
    $self->concatenate_to($fh, @_);
    close $fh;

    return $string;
}

sub concatenate_to {
    my $self = shift;
    my $dest = shift;
    
    FILE:
    while (my $file = shift @_) {
        my $fh;
        
        if (not open $fh, '<', $file) {
            print $dest qq[/* WARNING: Unable to open file '$file': $! */\n];
            next FILE;
        }
        
        IMPORT:
        while (my $line = <$fh>) {
            if ($line =~ /$AT_IMPORT/) {
                my $import = $1;
                my $media  = $2;

                if ( $import =~ m{^https?://} ) {
                    # Skip remote URLs
                    print $dest $line;
                    next IMPORT;
                }

                # We need the path relative to where we're importing it from
                my @spec = File::Spec->splitpath( $file );
                my $import_path = File::Spec->catpath( @spec[0,1], $import );

                if ($import_path eq $file) {
                    # We're in a direct loop, don't import this
                    print $dest "/** Skipping: \n", $line, "  */\n\n";
                    next IMPORT;
                }

                print $dest "\n/**\n  * From $file: $line  */\n\n";
                
                if (defined $media) {
                    print $dest "\@media $media {\n";
                    $self->concatenate_to($dest, $import_path);
                    print $dest "}\n";
                }
                else {
                    $self->concatenate_to($dest, $import_path);
                }

                print $dest "\n/** End of $import */\n\n";
            }
            else {
                print $dest $line;
                last IMPORT if not $line =~ /^\s*$/;
            }
        }
        print $dest $_ while <$fh>;
        close $fh;
    }
}

=head1 BUGS

At the current time, comments are not skipped.  This means comments happening
before @import statements at the top of a file will cause the @import rules
to not be parsed.  Make sure the @import rules are the very first thing in
the file (and only one per line).

Only direct @import loops (i.e. where a file imports itself) are checked
and skipped.  It's easy enough to get this module in a loop.  Don't do it.

All other bugs should be reported via
L<http://rt.cpan.org/Public/Dist/Display.html?Name=CSS-Squish>
or L<bugs-CSS-Squish@rt.cpan.org>.

=head1 AUTHOR

Thomas Sibley <trs@bestpractical.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

