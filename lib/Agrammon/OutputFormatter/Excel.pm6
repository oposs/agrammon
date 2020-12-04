use v6;
use Agrammon::Model;
use Agrammon::Outputs;
use Agrammon::Outputs::FilterGroupCollection;
use Spreadsheet::XLSX;
use Spreadsheet::XLSX::Styles;

# TODO: make output match current Agrammon Excel export
sub input-output-as-excel(
    Str $dataset-name, Agrammon::Model $model,
    Agrammon::Outputs $outputs, Agrammon::Inputs $inputs, $reports,
    Str $language, $prints,
    Bool $include-filters, Bool $all-filters
) is export {
    warn '**** input-output-as-excel() not yet completely implemented';

    my $workbook = Spreadsheet::XLSX.new;

    # prepare sheets
    my $output-sheet = $workbook.create-worksheet('Ergebnisse');
    my $output-sheet-formatted = $workbook.create-worksheet('Ergebnisse formatiert');
    for ($output-sheet, $output-sheet-formatted) -> $sheet {
        $sheet.set(0, 0, $dataset-name, :bold);
        $sheet.columns[0] = Spreadsheet::XLSX::Worksheet::Column.new:
                :custom-width, :width(50);
        $sheet.columns[2] = Spreadsheet::XLSX::Worksheet::Column.new:
                :custom-width, :width(32);
    }

    my $input-sheet = $workbook.create-worksheet('Eingaben');
    my $input-sheet-formatted = $workbook.create-worksheet('Eingaben formatiert');
    for ($input-sheet, $input-sheet-formatted) -> $sheet {
        $sheet.set(0, 0, $dataset-name, :bold);
    }

    # TODO: add inputs

    my @prints = $reports[+$prints]<data>;
    my %lang-labels;
    # add outputs
    my @print-set;
    for @prints -> @print {
        for @print -> $print {
            @print-set.push($print<print>);
            %lang-labels{$print<print>} = $print<langLabels>;
        }
    }

    my $row = 2;
    my @records;
    my $last-order = -1;
    for sorted-kv($outputs.get-outputs-hash) -> $module, $_ {
        when Hash {
            for sorted-kv($_) -> $output, $raw-value {
                my $value = flat-value($raw-value // 'UNDEFINED');
                my $var-print = $model.output-print($module, $output) ~ ',All';
                if not $prints or $var-print.split(',') ∩ @print-set {
                    my $print = ($var-print.split(',') ∩ @print-set).keys[0];
                    my $order = $model.output-labels($module, $output)<sort> || $last-order;
                    my $unit  = $model.output-unit($module, $output, $language);
                    my $output-label = $language ?? $model.output-labels($module, $output){$language} !! $output;
                    my $unit-label   = $language ?? $model.output-units($module, $output){$language}  !! $unit;
                    @records.push(%( :module(''), :$output-label, :$value, :$unit-label, :$order, :$print));
                    if $include-filters {
                        if $raw-value ~~ Agrammon::Outputs::FilterGroupCollection && $raw-value.has-filters {
                            push-filters(@records, $module, $model, $raw-value, $unit, $language, $order,
                            :$all-filters);
                        }
                    }
                    $last-order = $order;
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
                            my $print = ($var-print.split(',') ∩ @print-set).keys[0];
                            my $order = $model.output-labels($module, $output)<sort> || $last-order;
                            my $unit  = $model.output-unit($module, $output, $language);
                            my $output-label = $language ?? $model.output-labels($module, $output){$language} !! $output;
                            my $unit-label   = $language ?? $model.output-units($module, $output){$language}  !! $unit;
                            @records.push(%( :module(''), :$output-label, :$value, :$unit-label, :$order, :$print));
                            if $include-filters {
                                if $raw-value ~~ Agrammon::Outputs::FilterGroupCollection && $raw-value
                                .has-filters {
                                    push-filters(@records, $q-name, $model, $raw-value, $unit-label, $language,
                                    $order, :$all-filters);
                                }
                            }
                            $last-order = $order;
                        }
                    }
                }
            }
        }
    }

    my $col = 0;
    my $last-print = '';
    for @records.sort(+*.<order>) -> %rec {
        my $print = %rec<print>; # can be undefined or empty
        if $print and $print ne $last-print {
            $output-sheet.set($row, $col+0, %lang-labels{$print}{$language}, :bold);
            $last-print = $print;
            $row++;
        }
        $output-sheet.set($row, $col+1, %rec<module>);
        $output-sheet.set($row, $col+2, %rec<output-label> // 'Output: ???');
        $output-sheet.set($row, $col+3, %rec<value>, :number-format('#,###'));
        $output-sheet.set($row, $col+4, %rec<unit-label> // 'Unit: ???');
        $output-sheet.set($row, $col+5, %rec<order>);
        $row++;
    }
    return $workbook;
}

sub push-filters(@records, $module, $model, Agrammon::Outputs::FilterGroupCollection $collection,
                   $unit, $language, $order, Bool :$all-filters) {
    my @results = $collection.results-by-filter-group(:all($all-filters));
    for @results {
        my %keyFilters := .key;
        my %filters := translate-filter-keys($model, %keyFilters);
        my $value := .value;
#        we might need the %label for multiple filter groups later
#        for %filters.kv -> %label, %enum {
        for %filters.values -> %enum {
            @records.push( %( :$module, :output-label(%enum{$language}), :$value, :unit-label($unit), :$order) );
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
