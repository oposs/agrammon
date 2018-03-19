use Agrammon::Model;
use Text::CSV;

sub output-as-csv(Str $simulation-name, Str $dataset-id, Agrammon::Model $model,
                  %outputs, Str $unit-language --> Str) is export {
    my @lines;
    my $csv = Text::CSV.new(sep => ';', eol => "\n");
    for %outputs.kv -> $module, %module-outputs {
        for %module-outputs.kv -> $output, $value {
            $csv.combine($simulation-name, $dataset-id, $module, $output, $value,
                $model.output-unit($module, $output, $unit-language));
            push @lines, $csv.string;
        }
    }
    return @lines.join;
}
