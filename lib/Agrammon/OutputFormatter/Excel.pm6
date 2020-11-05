use Agrammon::Model;
use Agrammon::Outputs;
use Spreadsheet::XLSX;

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
    my $input-sheet = $workbook.create-worksheet('Eingabe-Parameter');
    my $input-sheet-formatted = $workbook.create-worksheet('Eingabe-Parameter formatiert');

    $output-sheet.set(0, 0, $dataset-name, :bold);
    $output-sheet.columns[0] = Spreadsheet::XLSX::Worksheet::Column.new:
            :custom-width, :width(50);
    $output-sheet.columns[2] = Spreadsheet::XLSX::Worksheet::Column.new:
            :custom-width, :width(32);
    my $row = 2;
    for sorted-kv($outputs.get-outputs-hash) -> $module, $_ {
        my $col = 0;
        my $n = 0;
        when Hash {
            for sorted-kv($_) -> $output, $value {
                my $val = flat-value($value // 'UNDEFINED');
                my $var-print = $model.output-print($module, $output) ~ ',All';
                if not $prints or $var-print.split(',') ∩ @print-set {
                    $n++;
                    my $unit = $model.output-unit($module, $output, $language);
                    $output-sheet.set($row, $col+0, $module);
                    $output-sheet.set($row, $col+2, $output);
                    $output-sheet.set($row, $col+3, $val, :number-format('#,###'));
                    $output-sheet.set($row, $col+4, $unit);

# TODO
#                    if $include-filters {
#                        if $value ~~ Agrammon::Outputs::FilterGroupCollection && $value.has-filters {
#                            render-filters(@module-lines, $value, $unit, $indent, :$all-filters);
#                        }
#                    }
                    $row++;
                }
            }
        }
        when Array {
            for sorted-kv($_) -> $instance-id, %instance-outputs {
                for sorted-kv(%instance-outputs) -> $fq-name, %values {
                    my $q-name = $module ~ '[' ~ $instance-id ~ ']' ~ $fq-name.substr($module.chars);
                    for sorted-kv(%values) -> $output, $value {
                        my $val = flat-value($value // 'UNDEFINED');
                        my $var-print = $model.output-print($module, $output) ~ ',All';
                        if not $prints or $var-print.split(',') ∩ @print-set {
                            $n++;
                            my $unit = $model.output-unit($module, $output, $language);
                            $output-sheet.set($row, $col+0, $module);
                            $output-sheet.set($row, $col+1, $q-name);
                            $output-sheet.set($row, $col+2, $output);
                            $output-sheet.set($row, $col+3, $val, :number-format('#,###'));
                            $output-sheet.set($row, $col+4, $unit);

# TODO
#                            if $include-filters {
#                                if $value ~~ Agrammon::Outputs::FilterGroupCollection && $value.has-filters {
#                                    render-filters(@module-lines, $value, $unit, $indent, :$all-filters);
#                                }
#                            }
                            $row++;
                        }
                    }
                }
            }
        }
        NEXT { # empty line between sections
            $row++ if $n;
        }
    }

    return $workbook;
}

sub sorted-kv($_) {
    .sort(*.key).map({ |.kv })
}

multi sub flat-value($value) {
    return $value ~~ Real ?? $value.Real !! $value;
}

multi sub flat-value(Agrammon::Outputs::FilterGroupCollection $collection) {
    my $value = +$collection;
    $value = $value.Real if $value ~~ Real;
    return $value;
}
