use v6;
use Agrammon::Model;
use Agrammon::Outputs;
use Agrammon::Outputs::FilterGroupCollection;
use Spreadsheet::XLSX;
use Spreadsheet::XLSX::Styles;

# TODO: make output match current Agrammon Excel export
sub output-as-excel(
    Str $dataset-name, Agrammon::Model $model,
    Agrammon::Outputs $outputs, Str $language,
    $prints, $include-filters, Bool :$all-filters = False
) is export {
    warn '**** output-as-excel() not yet completely implemented';

    my @print-set = $prints.split(',') if $prints;

    my $workbook = Spreadsheet::XLSX.new;
    my $output-sheet = $workbook.create-worksheet('Ergebnisse');
    my $output-sheet-formatted = $workbook.create-worksheet('Ergebnisse formatiert');

    # TODO: add input data
    my $input-sheet = $workbook.create-worksheet('Eingaben');
    my $input-sheet-formatted = $workbook.create-worksheet('Eingaben formatiert');

    for ($output-sheet, $output-sheet-formatted) -> $sheet {
        $sheet.set(0, 0, $dataset-name, :bold);
        $sheet.columns[0] = Spreadsheet::XLSX::Worksheet::Column.new:
                :custom-width, :width(50);
        $sheet.columns[2] = Spreadsheet::XLSX::Worksheet::Column.new:
                :custom-width, :width(32);
    }

    my $row = 2;
    my $last-module = '';
    for sorted-kv($outputs.get-outputs-hash) -> $module, $_ {
        my $col = 0;
        my $n = 0;
        when Hash {
            for sorted-kv($_) -> $output, $raw-value {
                my $value = flat-value($raw-value // 'UNDEFINED');
                my $var-print = $model.output-print($module, $output) ~ ',All';
                if not $prints or $var-print.split(',') ∩ @print-set {
                    $n++;
                    my $unit = $model.output-unit($module, $output, $language);
                    my $output-label = $language ?? $model.output-labels($module, $output){$language} !! $output;
                    my $unit-label   = $language ?? $model.output-units($module, $output){$language}  !! $unit;

                    if $module ne $last-module {
                        $output-sheet.set($row, $col + 0, $module);
                        $last-module = $module;
                    }
                    $output-sheet.set($row, $col+2, $output-label);
                    $output-sheet.set($row, $col+3, $value, :number-format('#,###'));
                    $output-sheet.set($row, $col+4, $unit-label);
                    $row++;
                    if $include-filters {
                        if $raw-value ~~ Agrammon::Outputs::FilterGroupCollection && $raw-value.has-filters {
                            render-filters($output-sheet, $row, $col, $model, $raw-value, $unit,  $language, :$all-filters);
                        }
                    }
                }
            }
        }
        when Array {
            for sorted-kv($_) -> $instance-id, %instance-outputs {
                for sorted-kv(%instance-outputs) -> $fq-name, %values {
                    my $q-name = $module ~ '[' ~ $instance-id ~ ']' ~ $fq-name.substr($module.chars);
                    for sorted-kv(%values) -> $output, $raw-value {
                        my $value = flat-value($raw-value // 'UNDEFINED');
                        my $var-print = $model.output-print($module, $output) ~ ',All';
                        if not $prints or $var-print.split(',') ∩ @print-set {
                            $n++;
                            my $unit = $model.output-unit($module, $output, $language);
                            my $output-label = $language ?? $model.output-labels($module, $output){$language} !! $output;
                            my $unit-label   = $language ?? $model.output-units($module, $output){$language}  !! $unit;

                            if $module ne $last-module {
                                $output-sheet.set($row, $col + 0, $module);
                                $last-module = $module;
                            }
                            $output-sheet.set($row, $col+1, $q-name);
                            $output-sheet.set($row, $col+2, $output-label // 'Output: ???');
                            $output-sheet.set($row, $col+3, $value, :number-format('#,###'));
                            $output-sheet.set($row, $col+4, $unit-label // 'Unit: ???');
                            $row++;
                            if $include-filters {
                                if $raw-value ~~ Agrammon::Outputs::FilterGroupCollection && $raw-value.has-filters {
                                    render-filters($output-sheet, $row, $col, $model, $raw-value, $unit, $language, :$all-filters);
                                }
                            }
                        }
                    }
                }
            }
        }
        NEXT $row++ if $n; # empty line between sections
    }

    return $workbook;
}

sub render-filters($sheet, $row is rw, $col, $model, Agrammon::Outputs::FilterGroupCollection $collection,
                   $unit, $language, Bool :$all-filters) {
    my @results = $collection.results-by-filter-group(:all($all-filters));
    for @results {
        my %keyFilters := .key;
        my %filters := translate-filter-keys($model, %keyFilters);
        my $value := .value;
#        we might need the %label for multiple filter groups later
#        for %filters.kv -> %label, %enum {
        for %filters.values -> %enum {
            $sheet.set($row, $col+2, %enum{$language}, :horizontal-align(RightAlign));
            $sheet.set($row, $col+3, $value, :number-format('#,###'));
            $sheet.set($row, $col+4, $unit);
            $row++;
        }
    }
}

sub sorted-kv($_) {
    .sort(*.key).map({ |.kv })
}

multi sub flat-value($value) {
    $value
}

multi sub flat-value(Agrammon::Outputs::FilterGroupCollection $collection) {
    +$collection
}
