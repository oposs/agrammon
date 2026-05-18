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
        # `accepts` is a comma-separated list of foreign enum keys this
        # option accepts as aliases (cross-version migration). Preserve
        # underscores and split on commas; do not treat as language text.
        if $l eq 'accepts' {
            %opt-lang{$l} = $o.split(/\s* ',' \s*/).grep(*.chars).list;
        }
        else {
            $o ~~ s:g/_/ /;
            %opt-lang{$l} = $o;
        }
    }
    %opt-lang
}
