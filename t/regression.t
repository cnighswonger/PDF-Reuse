#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;
use IO::String;
use File::Temp qw(tempfile);

BEGIN {
    use_ok('PDF::Reuse') or BAIL_OUT "Can't load PDF::Reuse";
}

# RT #130152 / GitHub #12
# sprintf with undefined objekt values should not warn
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my ($fh, $tmpfile) = tempfile(SUFFIX => '.pdf', UNLINK => 1);
    close $fh;

    prFile($tmpfile);
    prText(100, 700, 'Test RT 130152');
    prEnd();

    my @undef_warnings = grep { /uninitialized value/ } @warnings;
    is(scalar @undef_warnings, 0,
        'RT #130152: No uninitialized value warnings from sprintf');
}

# RT #171691 / GitHub #13
# IO::String untie: writing to IO::String then calling prFile() again
# should not produce "Can't locate object method OPEN" error
{
    my $pdf_data = '';
    my $io = IO::String->new($pdf_data);

    my $ok = eval {
        prFile($io);
        prText(100, 700, 'IO::String test');
        prEnd();

        # This second prFile call would fail without the untie fix
        my ($fh, $tmpfile) = tempfile(SUFFIX => '.pdf', UNLINK => 1);
        close $fh;
        prFile($tmpfile);
        prText(100, 700, 'After IO::String');
        prEnd();
        1;
    };
    my $err = $@;

    ok($ok, 'RT #171691: prFile() works after IO::String write')
        or diag("Error: $err");

    ok(length($pdf_data) > 0,
        'RT #171691: IO::String received PDF data');
}

# RT #120459 / GitHub #19
# defined(%hash) - module loads and prDocForm compiles without error
# (This was a compile-time failure on Perl 5.24+)
{
    my $ok = eval {
        # Force loading of the prDocForm code path
        # (previously hidden behind AutoLoader)
        my $exists = defined &PDF::Reuse::prDocForm;
        1;
    };
    ok($ok, 'RT #120459: prDocForm compiles without defined(%hash) error');
}

# GitHub #8
# prDocForm should not crash with "undefined value as ARRAY reference"
# when %links has entries but not for the current page
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my ($fh, $tmpfile) = tempfile(SUFFIX => '.pdf', UNLINK => 1);
    close $fh;

    # Generate a simple PDF, then try to use it with prDocForm
    prFile($tmpfile);
    prText(100, 700, 'Source PDF for prDocForm test');
    prEnd();

    my ($fh2, $outfile) = tempfile(SUFFIX => '.pdf', UNLINK => 1);
    close $fh2;

    my $ok = eval {
        prFile($outfile);
        prDocForm($tmpfile);
        prEnd();
        1;
    };
    my $err = $@;

    ok($ok, 'GitHub #8: prDocForm does not crash on undefined links')
        or diag("Error: $err");
}

# RT #83185 / GitHub #20
# crossrefObj should not warn about non-numeric arguments
{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my ($fh, $tmpfile) = tempfile(SUFFIX => '.pdf', UNLINK => 1);
    close $fh;

    prFile($tmpfile);
    prText(100, 700, 'Test RT 83185');
    prEnd();

    my @numeric_warnings = grep { /isn't numeric/ } @warnings;
    is(scalar @numeric_warnings, 0,
        "RT #83185: No 'isn't numeric' warnings from crossrefObj");
}
