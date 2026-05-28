#!/usr/bin/perl
#
# po-locations.pl - normalise "#:" location comments in qooxdoo .po files.
#
# Run after `qx compile --update-po-files`. The qooxdoo compiler owns the
# msgid set but writes only ONE "#:" reference per entry, chosen
# non-deterministically when a string is used in several files. That makes
# the comment flip-flop between builds and produces meaningless diffs.
#
# This script rewrites the "#:" lines so each entry lists ALL source files
# that reference its msgid, sorted and file-only (no :line numbers, which
# would churn on every unrelated edit). msgid/msgstr content is never
# touched, so a recompile with no source change yields a byte-identical
# file, while a genuinely new/moved usage shows as a clean one-line diff.
#
# Usage: perl tools/po-locations.pl source/translation/*.po

use strict;
use warnings;
use File::Find;

my $SRCROOT = 'source/class';

# --- 1) index every source file's text, keyed by path relative to SRCROOT
my %content;        # relpath => file text
my @files;          # sorted list of relpaths
find({ no_chdir => 1, wanted => sub {
    my $path = $File::Find::name;            # source/class/agrammon/Foo.js
    return unless $path =~ /\.js$/ && -f $path;
    (my $rel = $path) =~ s{^\Q$SRCROOT\E/}{};
    open my $fh, '<:encoding(UTF-8)', $path or return;
    local $/;
    $content{$rel} = <$fh>;
    close $fh;
    push @files, $rel;
} }, $SRCROOT);
@files = sort @files;

# --- 2) helpers
sub po_unescape {
    my ($s) = @_;
    $s =~ s/\\n/\n/g;
    $s =~ s/\\t/\t/g;
    $s =~ s/\\"/"/g;
    $s =~ s/\\\\/\\/g;
    return $s;
}

# files that reference the given raw literal as a quoted tr() argument.
# Requiring the surrounding quote avoids matching a short msgid inside a
# longer string or an unrelated identifier.
my %loc_cache;
sub locations_for {
    my ($raw) = @_;
    return @{ $loc_cache{$raw} } if $loc_cache{$raw};
    my $dq = '"'  . $raw . '"';
    my $sq = "'"  . $raw . "'";
    my @hits;
    for my $rel (@files) {
        my $t = $content{$rel};
        push @hits, $rel
            if index($t, $dq) >= 0 || index($t, $sq) >= 0;
    }
    $loc_cache{$raw} = \@hits;
    return @hits;
}

# pull the (possibly multi-line) msgid out of an entry's kept lines
sub extract_msgid {
    my ($lines) = @_;
    my ($msgid, $collecting);
    for my $l (@$lines) {
        if ($l =~ /^msgid\s+"(.*)"\s*$/) {
            $msgid     = $1;
            $collecting = 1;
        }
        elsif ($collecting && $l =~ /^"(.*)"\s*$/) {
            $msgid .= $1;
        }
        elsif ($collecting) {
            last;
        }
    }
    return defined $msgid ? po_unescape($msgid) : undef;
}

# rewrite one entry (array of its lines) into the output list
sub flush_entry {
    my ($entry, $out) = @_;
    return unless @$entry;

    my @orig_locs = grep {  $_ =~ /^#: / } @$entry;   # what qx wrote
    my @kept      = grep {  $_ !~ /^#: / } @$entry;   # everything else
    my $msgid     = extract_msgid(\@kept);
    my @found     = (defined $msgid && length $msgid) ? locations_for($msgid) : ();

    # Use the complete, sorted grep result when we found references. When
    # we find none (e.g. the msgid is built by string concatenation, which
    # the qooxdoo AST folds but a literal grep cannot see), preserve qx's
    # own location lines rather than dropping the hint entirely.
    my @locs = @found ? map { "#: $_\n" } @found : @orig_locs;

    my $inserted = 0;
    for my $l (@kept) {
        if (!$inserted && $l =~ /^msgid\b/) {
            push @$out, @locs;
            $inserted = 1;
        }
        push @$out, $l;
    }
}

# --- 3) process each .po file
for my $po (@ARGV) {
    open my $in, '<:encoding(UTF-8)', $po or die "open $po: $!";
    my @lines = <$in>;
    close $in;

    my (@out, @entry);
    for my $line (@lines) {
        if ($line =~ /^\s*$/) {                   # blank line ends an entry
            flush_entry(\@entry, \@out);
            @entry = ();
            push @out, $line;
        }
        else {
            push @entry, $line;
        }
    }
    flush_entry(\@entry, \@out);                   # trailing entry, no blank

    open my $w, '>:encoding(UTF-8)', $po or die "write $po: $!";
    print $w @out;
    close $w;
}
