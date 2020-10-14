use Agrammon::Model;
use Agrammon::Outputs;
use Spreadsheet::XLSX;

# TODO: output Excel instead of CSV
sub output-as-excel(Str $simulation-name, Str $dataset-id, Agrammon::Model $model,
                  Agrammon::Outputs $outputs, Str $unit-language --> Str) is export {
    return (gather for $outputs.get-outputs-hash.sort(*.key) {
        my $module = .key;
        if .value.isa(Hash) {
            for .value.sort(*.key) {
                take ($simulation-name, $dataset-id, $module, .key, flat-value(.value),
                        $model.output-unit($module, .key, $unit-language)).join(';');
            }
        }
        else {
            for .value.sort(*.key) {
                my $instance-id = .key;
                for .value.sort(*.key) {
                    my $fq-name = .key;
                    my $q-name = $module ~ '[' ~ $instance-id ~ ']' ~ $fq-name.substr($module.chars);
                    for .value.sort(*.key) {
                        take ($simulation-name, $dataset-id, $q-name, .key, flat-value(.value) // '',
                                $model.output-unit($fq-name, .key, $unit-language)).join(';');
                    }
                }
            }
        }
    }).join("\n") ~ "\n";
}

multi sub flat-value($value) {
    $value
}
multi sub flat-value(Agrammon::Outputs::FilterGroupCollection $collection) {
    +$collection
}