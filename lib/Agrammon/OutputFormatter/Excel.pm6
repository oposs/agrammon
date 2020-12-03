use v6;
use Agrammon::Model;
use Agrammon::Outputs;
use Agrammon::Outputs::FilterGroupCollection;
use Spreadsheet::XLSX;
use Spreadsheet::XLSX::Styles;

# TODO: make output match current Agrammon Excel export
sub input-output-as-excel(
    Str $dataset-name, Agrammon::Model $model,
    Agrammon::Outputs $outputs, Agrammon::Inputs $inputs,
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


    # add outputs
    my @print-set = $prints.split(',') if $prints;
    my $row = 2;
    my @records;
    for sorted-kv($outputs.get-outputs-hash) -> $module, $_ {
        my $col = 0;
        when Hash {
            for sorted-kv($_) -> $output, $raw-value {
                my $value = flat-value($raw-value // 'UNDEFINED');
                my $var-print = $model.output-print($module, $output) ~ ',All';
                if not $prints or $var-print.split(',') ∩ @print-set {
                    my $order        = $model.output-labels($module, $output)<sort> || 'no order';
                    my $unit         = $model.output-unit($module, $output, $language);
                    my $output-label = $language ?? $model.output-labels($module, $output){$language} !! $output;
                    my $unit-label   = $language ?? $model.output-units($module, $output){$language}  !! $unit;
                    @records.push( %( :$module, :$output-label, :$value, :$unit-label, :$order ) );
                    if $include-filters {
                        if $raw-value ~~ Agrammon::Outputs::FilterGroupCollection && $raw-value.has-filters {
                            push-filters(@records, $module, $model, $raw-value, $unit, $language, $order, :$all-filters);
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
                            my $order        = $model.output-labels($module, $output)<sort> || 'no order';
                            my $unit         = $model.output-unit($module, $output, $language);
                            my $output-label = $language ?? $model.output-labels($module, $output){$language} !! $output;
                            my $unit-label   = $language ?? $model.output-units($module, $output){$language}  !! $unit;
                            @records.push( %( :module($q-name), :$output-label, :$value, :$unit-label, :$order ) );
                            if $include-filters {
                                if $raw-value ~~ Agrammon::Outputs::FilterGroupCollection && $raw-value.has-filters {
                                    push-filters(@records, $q-name, $model, $raw-value, $unit-label, $language, $order, :$all-filters);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    my $col = 0;
    my $last-module = '';
    for @records.sort(+*.<order>) -> %rec {
        %rec<module> ~~ / (.+?) '::' /;
        my $module = $0 // %rec<module>;
        if $module ne $last-module {
            $output-sheet.set($row, $col+0, ~$module, :bold);
            $last-module = $module;
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
