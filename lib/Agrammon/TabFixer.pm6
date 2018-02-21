#| Fixes any tabs in the input string to four spaces, and warns about each
#| one.
sub fix-tabs(Str $in) is export {
    return $in.subst(:g, /\t/, {
        state @line-starts = $in.split(/<?[\n]>/).map(*.chars);
        my $line = 1 + @line-starts.first(:k, {
            state $cur-pos += $_;
            $/.pos < $cur-pos
        });
        warn "Tab at line $line replaced with four spaces";
        "    "
    });
}
