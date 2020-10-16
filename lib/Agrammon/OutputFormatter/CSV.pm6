use Agrammon::Model;
use Agrammon::Outputs;

sub output-as-csv(
        $simulation-name, $dataset-id, Agrammon::Model $model,
        Agrammon::Outputs $outputs, Str $unit-language,
        $with-filters? --> Str
) is export {
    # TODO: handle with-filters
    return (gather for $outputs.get-outputs-hash.sort(*.key) {
        my $module = .key;
        my $prefix = "$simulation-name;$dataset-id" if $simulation-name;
        if .value.isa(Hash) {
            for .value.sort(*.key) {
                my @data = (
                    $module, .key, flat-value(.value) // '',
                    $model.output-unit($module, .key, $unit-language)
                );
                @data.unshift($prefix) if $prefix;
                take @data.join(';');
            }
         }
        else {
            for .value.sort(*.key) {
                my $instance-id = .key;
                for .value.sort(*.key) {
                    my $fq-name = .key;
                    my $q-name = $module ~ '[' ~ $instance-id ~ ']' ~ $fq-name.substr($module.chars);
                    for .value.sort(*.key) {
                        my @data = (
                            $q-name, .key, flat-value(.value) // '',
                            $model.output-unit($fq-name, .key, $unit-language)
                        );
                        @data.unshift($prefix) if $prefix;
                        take @data.join(';');
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
