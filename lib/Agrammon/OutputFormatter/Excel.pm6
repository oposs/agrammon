use Agrammon::Model;
use Agrammon::Outputs;
use Spreadsheet::XLSX;
use Agrammon::OutputFormatter::CSV;

# TODO: output Excel instead of CSV
sub output-as-excel(
    Str $dataset-name, Agrammon::Model $model,
    Agrammon::Outputs $outputs, Str $unit-language,
    $with-filters? --> Str
) is export {
    warn '**** output-as-excel() not yet completely implemented';
    my $simulation-name;
    output-as-csv(
        $simulation-name, $dataset-name, $model,
        $outputs, $unit-language, $with-filters
    );
}

multi sub flat-value($value) {
    $value
}
multi sub flat-value(Agrammon::Outputs::FilterGroupCollection $collection) {
    +$collection
}
