use strict;
use warnings;

package CSS::Squish;

$CSS::Squish::VERSION = '0.04';

# Setting this to true will enable lots of debug logging about what
# CSS::Squish is doing
$CSS::Squish::DEBUG   = 0;

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

my @ROOTS = qw( );

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
    
    $self->_debug("Opening scalar as file");
    
    open my $fh, '>', \$string or die "Can't open scalar as file! $!";
    $self->concatenate_to($fh, @_);

    $self->_debug("Closing scalar as file");
    close $fh;

    return $string;
}

sub concatenate_to {
    my $self = shift;
    my $dest = shift;

    $self->_debug("Looping over list of files: ", join(", ", @_), "\n");
    
    FILE:
    while (my $file = shift @_) {
        my $fh;
        
        $self->_debug("Opening '$file'");
        if (not open $fh, '<', $file) {
            $self->_debug("Skipping '$file' due to error");
            print $dest qq[/* WARNING: Unable to open file '$file': $! */\n];
            next FILE;
        }
        
        IMPORT:
        while (my $line = <$fh>) {
            if ($line =~ /$AT_IMPORT/) {
                my $import = $1;
                my $media  = $2;

                $self->_debug("Processing import '$import'");
                
                if ( $import =~ m{^https?://} ) {
                    $self->_debug("Skipping import because it's a remote URL");

                    # Skip remote URLs
                    print $dest $line;
                    next IMPORT;
                }

                # We need the path relative to where we're importing it from
                my @spec = File::Spec->splitpath( $file );

                # This first searches for the import relative to the file
                # it is imported from and then in any user-specified roots
                my $import_path = $self->_resolve_file(
                                        $import,
                                        File::Spec->catpath( @spec[0,1], '' ),
                                        $self->roots
                                  );

                if ( not defined $import_path ) {
                    $self->_debug("Skipping import of '$import'");
                    
                    print $dest qq[/* WARNING: Unable to find import '$import' */\n];
                    print $dest $line;
                    next IMPORT;
                }

                if ($import_path eq $file) {
                    $self->_debug("Skipping import because it's a loop");
                
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
        $self->_debug("Printing the rest of '$file'");
        print $dest $_ while <$fh>;

        $self->_debug("Closing '$file'");
        close $fh;
    }
}

=head2 B<CSS::Squish-E<gt>roots(@dirs)>

A getter/setter for additional paths to search when looking for imported
files.  The paths specified here are searched after trying to find the import
relative to the file from which it is imported.  This is useful if your
server has multiple document roots from which your CSS imports files.

=cut

sub roots {
    my $self = shift;
    @ROOTS = @_ if @_;
    return @ROOTS;
}

sub _resolve_file {
    my $self = shift;
    my $file = shift;

    for my $root ( @_ ) {
        my @spec = File::Spec->splitpath( $root, 1 );
        my $path = File::Spec->catpath( @spec[0,1], $file );
        
        return $path if -e $path;
    }
    return;
}

sub _debug {
    my $self = shift;
    warn( ( caller(1) )[3], ": ", @_, "\n") if $CSS::Squish::DEBUG;
}

=head1 BUGS AND SHORTCOMINGS

At the current time, comments are not skipped.  This means comments happening
before @import statements at the top of a file will cause the @import rules
to not be parsed.  Make sure the @import rules are the very first thing in
the file (and only one per line).

Only direct @import loops (i.e. where a file imports itself) are checked
and skipped.  It's easy enough to get this module in a loop.  Don't do it.

As of now, server-relative URLs (instead of file-relative URLs) will not work
correctly.

All other bugs should be reported via
L<http://rt.cpan.org/Public/Dist/Display.html?Name=CSS-Squish>
or L<bug-CSS-Squish@rt.cpan.org>.

=head1 AUTHOR

Thomas Sibley <trs@bestpractical.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

