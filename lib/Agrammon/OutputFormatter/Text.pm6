use Agrammon::Model;
use Agrammon::Outputs;

sub output-as-text(Agrammon::Model $model, Agrammon::Outputs $outputs, Str $language,
                   Str $prints, Bool $include-filters --> Str) is export {
    my @lines;
    my @print-set = $prints.split(',');
    for sorted-kv($outputs.get-outputs-hash) -> $module, $_ {
        my $n = 0;
        my @module-lines;
        push @module-lines, $module;
        when Hash {
            for sorted-kv($_) -> $output, $value {
                my $val = flat-value($value // 'UNDEFINED');
                my $var-print = $model.output-print($module, $output) ~ ',All';
                if $var-print.split(',') ∩ @print-set {
                    $n++;
                    my $unit = $model.output-unit($module, $output, $language);
                    push @module-lines, "    $output = $val $unit";
                    if $include-filters {
                        if $value ~~ Agrammon::Outputs::FilterGroupCollection && $value.has-filters {
                            render-filters(@module-lines, $value, $unit, "    ");
                        }
                    }
                }
            }
        }
        when Array {
            for sorted-kv($_) -> $instance-id, %instance-outputs {
                for sorted-kv(%instance-outputs) -> $fq-name, %values {
                    my $q-name = $module ~ '[' ~ $instance-id ~ ']' ~ $fq-name.substr($module.chars);
                    push @module-lines, "    $q-name";
                    for sorted-kv(%values) -> $output, $value {
                        my $val = flat-value($value // 'UNDEFINED');
                        my $var-print = $model.output-print($module, $output) ~ ',All';
                        if $var-print.split(',') ∩ @print-set {
                            $n++;
                            my $unit = $model.output-unit($module, $output, $language);
                            push @module-lines, "        $output = $val $unit";
                            if $include-filters {
                                if $value ~~ Agrammon::Outputs::FilterGroupCollection && $value.has-filters {
                                    render-filters(@module-lines, $value, $unit, "    ");
                                }
                            }
                        }
                    }
                }
            }
        }
        NEXT {
            @lines.append: @module-lines if $n;
        }
    }
    return @lines.join("\n");
}

multi sub flat-value($value) {
    $value
}
multi sub flat-value(Agrammon::Outputs::FilterGroupCollection $collection) {
    +$collection
}

sub render-filters(@module-lines, Agrammon::Outputs::FilterGroupCollection $collection,
        $unit, $prefix) {
    my @results = $collection.results-by-filter-group;
    my $longest-filter = @results.map({ .key.map({ .key.chars + .value.chars }) }).flat.max + 1;
    for @results {
        my %filters := .key;
        my $value := .value;
        my @filters = %filters.map: { .key ~ '=' ~ .value };
        for @filters.kv -> $idx, $filter-id {
            my $padding = ' ' x $longest-filter - $filter-id.chars;
            push @module-lines, $idx == 0
                    ?? "$prefix  * $filter-id$padding    $value $unit"
                    !! "$prefix    $filter-id";
        }
    }
}

sub sorted-kv($_) {
    .sort(*.key).map({ |.kv })
}
