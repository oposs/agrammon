use v6;

sub timed(Str $title, &proc) is export {
    my $start = now;
    my \ret   = proc;
    my $end   = now;
    note sprintf "$title ran %.3f seconds", $end-$start;
    return ret;
}
