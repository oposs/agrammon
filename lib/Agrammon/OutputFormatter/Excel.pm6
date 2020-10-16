use Agrammon::Model;
use Agrammon::Outputs;
use Spreadsheet::XLSX;

# TODO: make output match current Agrammon Excel export
sub output-as-excel(
    Str $dataset-name, Agrammon::Model $model,
    Agrammon::Outputs $outputs, Str $unit-language,
    $with-filters?
) is export {
    warn '**** output-as-excel() not yet completely implemented';

    # Create a dummy workbook and worksheet with some cell values.
    my $workbook = Spreadsheet::XLSX.new;
    my $sheet-a = $workbook.create-worksheet($dataset-name);
    $sheet-a.set(0, 0, $dataset-name, :bold);
    $sheet-a.set(1, 1, 42, :number-format('#,###'));
    return $workbook;
}

multi sub flat-value($value) {
    $value
}
multi sub flat-value(Agrammon::Outputs::FilterGroupCollection $collection) {
    +$collection
}
