use v6;

sub timed(Str $title, &proc) is export {
    my $start = now;
    my \ret   = proc;
    my $end   = now;
    note sprintf "%s ran %.3f seconds", $title, $end-$start;
    return ret;
}
