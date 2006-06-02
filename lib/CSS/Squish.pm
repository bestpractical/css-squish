
package CSS::Squish;

=head1 NAME

CSS::Squish - Optimize CSS files

=head1 SYNOPSIS

 use CSS::Squish;

 open(FILE, 'main.css');
 my $concatenated = CSS::Squish->concatenate($css_file);

=head1 DESCRIPTION

The structure of this code blatantly stolen from JavaScript::Squish.

This module currently only supports concatenating CSS files by finding the
files which are being @include'd and inserting them into the current file.

This saves bandwidth and HTTP requests.

=head2 EXPORT

None by default.

"squish" may be exported via "use CSS::Squish qw(squish);"

=head1 METHODS

=head2 B<CSS::Squish-E<gt>squish($js [, %options] )>

Class method. This is a wrapper around all methods in here, to allow you to do all compacting operations in one call.

     my $squished = CSS::Squish->squish( $javascript );

Current supported options:

=over

=head2 B<CSS::Squish-E<gt>new()>

Constructor. Currently takes no options. Returns CSS::Squish object.

=head2 B<$djc-E<gt>data($js)>

If the option C<$js> is passed in, this sets the CSS that will be worked on.

If not passed in, this returns the CSS in whatever state it happens to be in (so you can step through, and pull the data out at any time).

=head2 B<$djc-E<gt>determine_line_ending()>

Method to automatically determine the line ending character in the source data.

=head2 B<$djc-E<gt>eol_char("\n")>

Method to set/override the line ending character which will be used to parse/join lines. Set to "\r\n" if you are working on a DOS / Windows formatted file.

=head2 B<$djc-E<gt>replace_final_eol()>

Prior to this being called, the end of line may not terminated with a new line character (especially after some of the steps above). This assures the data ends in at least one of whatever is set in C<$djc-E<gt>eol_char()>.

=head1 NOTES

The following should only cause an issue in rare and odd situations... If the input file is in dos format (line termination with "\r\n" (ie. CR LF / Carriage return Line feed)), we'll attempt to make the output the same. If you have a mixture of embeded "\r\n" and "\n" characters (not escaped, those are still safe) then this script may get confused and make them all conform to whatever is first seen in the file.

=head1 TODO

Actual implementation of concatenate()

=head1 BUGS

Unwritten code has no bugs. :-)

=head1 AUTHOR

Kevin Riggle <kevinr@bestpractical.com>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

use 5.00503;
use strict;
use Carp qw(croak carp);

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);

%EXPORT_TAGS = ( 'all' => [ qw( squish ) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw( );

$VERSION = '0.01';

sub squish {
    my $this = shift;

    # squish() can be used as a class method or instance method
    unless (ref $this)
    {
        $this = $this->new();
    }

    {
        my $data = (ref($_[0]) eq 'SCALAR') ? ${(shift)} : shift;
        $this->data($data);
    }
    my %opts = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

    # determine line ending
    print STDERR "Determining line ending format (LF || CRLF)...\n" if $opts{DEBUG};
    $this->determine_line_ending();

    # concatenate imported files
    print STDERR "Concatenating @import'd files...\n" if $opts{DEBUG};
    $this->concatenate();

    # replace final EOL
    print STDERR "Replace final EOL...\n" if $opts{DEBUG};
    $this->replace_final_eol();

    return $this->data;
}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $this = {
        data    => '',
        strings => [ ],
        comments => [ ],
        eol     => "\n",
        _strings_extracted  => 0, # status var
        _comments_extracted  => 0, # status var
        };
    bless $this, $class;

    return $this;
}

sub data {
    my $this = shift;
    
    if ($_[0]) {
        my $data = (ref($_[0]) eq 'SCALAR') ? ${$_[0]} : $_[0];
        $this->{data} = $_[0];
    } else {
        return $this->{data};
    }
}

sub eol_char {
    my $this = shift;

    if ($_[0]) {
        $this->{eol} = $_[0];
    } else {
        return $this->{eol};
    }
}

sub determine_line_ending {
    my $this = shift;

    # Where is the first LF character?
    my $lf_position = index($this->data, "\n");
    if ($lf_position == -1)
    {   # not found, set to default, cause it won't (shouldn't) matter
        $this->eol_char("\n");
    } else {
        if ($lf_position == 0)
        {   # found at first char, so there is no prior character to observe
            $this->eol_char("\n");
        } else {
            # Is the character immediately before it a CR?
            my $test_cr = substr($this->data, ($lf_position -1),1);
            if ($test_cr eq "\r")
            {
                $this->eol_char("\r\n");
            } else {
                $this->eol_char("\n");
            }
        }
    }
}

sub replace_final_eol {
    my $this = shift;

    my $eol  = $this->eol_char();
    my $data = $this->data;
    if ($data =~ /\r?\n$/) {
        $data =~ s/\r?\n$/$eol/;
    } else {
        $data .= $eol;
    }
    $this->data($data);
}

sub concatenate {
    my $this = shift;
    my $data = $this->data;
    
    while ( $data =~ /(.*)\n/g ) {
        my $line = $1;
        while ($line !~ /\@import (?:\"|/g)
    }
}

1;
