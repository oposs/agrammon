use v6;

sub parse-lang-values(Str $value, Str $context --> Hash) is export {
    my %opt-lang;
    for (split("\n", $value)) -> $ol {
        next unless $ol;
        my ($l, $o) = split(/ \s* '=' \s* /, $ol);
        if not $o {
            warn "Failed to parse language value for $context: ol=\>$ol\<";
            next;
        }
        $o ~~ s:g/_/ /;
        %opt-lang{$l} = $o;
    }
    %opt-lang
}
