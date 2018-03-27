use Agrammon::Model;
use Agrammon::Outputs;
use Text::CSV;

sub output-as-csv(Str $simulation-name, Str $dataset-id, Agrammon::Model $model,
                  Agrammon::Outputs $outputs, Str $unit-language --> Str) is export {
    my @lines;
    my $csv = Text::CSV.new(sep => ';', eol => "\n", quote => Str);
    for sorted-kv($outputs.get-outputs-hash) -> $module, $_ {
        when Hash {
            for sorted-kv($_) -> $output, $value {
                $csv.combine($simulation-name, $dataset-id, $module, $output, $value,
                        $model.output-unit($module, $output, $unit-language));
                push @lines, $csv.string;
            }
        }
        when Array {
            for sorted-kv($_) -> $instance-id, %instance-outputs {
                for sorted-kv(%instance-outputs) -> $fq-name, %values {
                    my $q-name = $module ~ '[' ~ $instance-id ~ ']' ~ $fq-name.substr($module.chars);
                    for sorted-kv(%values) -> $output, $value {
                        $csv.combine($simulation-name, $dataset-id, $q-name, $output, $value,
                                $model.output-unit($fq-name, $output, $unit-language));
                        push @lines, $csv.string;
                    }
                }
            }
        }
    }
    return @lines.join;
}

sub sorted-kv($_) {
    .sort(*.key).map({ |.kv })
}
