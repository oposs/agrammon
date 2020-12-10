use v6;
use Agrammon::Model;
use Agrammon::Outputs;
use Agrammon::OutputFormatter::CollectData;
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
                :custom-width, :width(20);
        $sheet.columns[1] = Spreadsheet::XLSX::Worksheet::Column.new:
                :custom-width, :width(10);
        $sheet.columns[2] = Spreadsheet::XLSX::Worksheet::Column.new:
                :custom-width, :width(32);
        $sheet.columns[3] = Spreadsheet::XLSX::Worksheet::Column.new:
                :custom-width, :width(20);
        $sheet.columns[4] = Spreadsheet::XLSX::Worksheet::Column.new:
                :custom-width, :width(10);
    }

    my $input-sheet = $workbook.create-worksheet('Eingaben');
    my $input-sheet-formatted = $workbook.create-worksheet('Eingaben formatiert');
    for ($input-sheet, $input-sheet-formatted) -> $sheet {
        $sheet.set(0, 0, $dataset-name, :bold);
        $sheet.columns[1] = Spreadsheet::XLSX::Worksheet::Column.new:
                :custom-width, :width(40);
        $sheet.columns[2] = Spreadsheet::XLSX::Worksheet::Column.new:
                :custom-width, :width(32);
        $sheet.columns[3] = Spreadsheet::XLSX::Worksheet::Column.new:
                :custom-width, :width(10);
    }
    $input-sheet.columns[0] = Spreadsheet::XLSX::Worksheet::Column.new:
            :custom-width, :width(20);
    $input-sheet-formatted.columns[0] = Spreadsheet::XLSX::Worksheet::Column.new:
            :custom-width, :width(10);

    # prepared data
    my %data = collect-data(
        $dataset-name, $model,
        $outputs, $inputs, $reports,
        $language, $prints,
        $include-filters, $all-filters
    );

    # TODO: fix sorting
    my @records := %data<inputs>;
    my $col = 0;
    my $row = 2;
    my $row-formatted = 2;
    my $last-print = '';
#    for @records.sort(+*.<order>) -> %rec {
    my $last-instance = '';
    my $last-module = '';
    for @records -> %rec {
        my $value = %rec<value>;
        my $value-translated;
        if %rec<enum> {
            $value-translated = %rec<enum>{$value}{$language};
        }

        # raw data
        $input-sheet.set($row, $col+0, %rec<gui>);
        $input-sheet.set($row, $col+1, %rec<instance>);
        $input-sheet.set($row, $col+2, %rec<input>);
        $input-sheet.set($row, $col+3, ($value // '???'), :number-format('#,#'), :horizontal-align(RightAlign));
        $input-sheet.set($row, $col+4, %rec<unit>);
        $row++;

        # formatted data
        my $instance = %rec<instance>;
        my $module = %rec<gui>;
        if $module ne $last-module {
            $input-sheet-formatted.set($row-formatted, $col+0, $module, :bold);
            $row-formatted++;
            $last-module = $module;
        }
        if $instance and $instance ne $last-instance {
            $input-sheet-formatted.set($row-formatted, $col+1, $instance, :bold);
            $row-formatted++;
            $last-instance = $instance;
        }
        $input-sheet-formatted.set($row-formatted, $col+1, %rec<input>);
        $input-sheet-formatted.set($row-formatted, $col+2, ($value-translated // $value // '???'), :number-format('#,#'), :horizontal-align(RightAlign));
        $input-sheet-formatted.set($row-formatted, $col+3, %rec<unit>);
        $row-formatted++;
    }

    # add outputs
    my @prints = $reports[+$prints]<data>;
    my %lang-labels;
    my @print-set;
    for @prints -> @print {
        for @print -> $print {
            @print-set.push($print<print>);
            %lang-labels{$print<print>} = $print<langLabels>;
        }
    }

    @records := %data<outputs>;
    $row = 2;
    $col = 0;
    $last-print = '';
    for @records.sort(+*.<order>) -> %rec {
        my $print = %rec<print>; # can be undefined or empty
        if $print and $print ne $last-print {
            $output-sheet.set($row, $col+0, %lang-labels{$print}{$language}, :bold);
            $last-print = $print;
            $row++;
        }
        $output-sheet.set($row, $col+1, %rec<module>);
        $output-sheet.set($row, $col+2, %rec<label> // 'Output: ???');
        $output-sheet.set($row, $col+3, %rec<value>, :number-format('#,###'));
        $output-sheet.set($row, $col+4, %rec<unit> // 'Unit: ???');
        $output-sheet.set($row, $col+5, %rec<order>);
        $row++;
    }
    return $workbook;
}
