use Agrammon::Model;
use Agrammon::Outputs;

sub output-as-text(Agrammon::Model $model,
                   Agrammon::Outputs $outputs, Str $unit-language,
                   Str $prints --> Str) is export {
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
                    push @module-lines, "    $output = $val " ~ $model.output-unit($module, $output, $unit-language);
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
                            push @module-lines, "        $output = $val " ~ $model.output-unit($module, $output, $unit-language);
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

sub sorted-kv($_) {
    .sort(*.key).map({ |.kv })
}
