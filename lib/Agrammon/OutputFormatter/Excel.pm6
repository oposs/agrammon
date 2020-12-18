use v6;
use Agrammon::Config;
use Agrammon::Model;
use Agrammon::Outputs;
use Agrammon::OutputFormatter::CollectData;
use Agrammon::Timestamp;
use Agrammon::Web::SessionUser;
use Spreadsheet::XLSX;
use Spreadsheet::XLSX::Styles;

sub input-output-as-excel(
    Agrammon::Config $cfg,
    Agrammon::Web::SessionUser $user,
    Str $dataset-name, Agrammon::Model $model,
    Agrammon::Outputs $outputs, Agrammon::Inputs $inputs, $reports,
    Str $language, $prints,
    Bool $include-filters, Bool $all-filters
) is export {
    my $workbook = Spreadsheet::XLSX.new;

    # prepare sheets
    my $output-sheet = $workbook.create-worksheet('Ergebnisse');
    my $output-sheet-formatted = $workbook.create-worksheet('Ergebnisse formatiert');
    my $input-sheet = $workbook.create-worksheet('Eingaben');
    my $input-sheet-formatted = $workbook.create-worksheet('Eingaben formatiert');
    my $timestamp = timestamp;
    my $model-version = $cfg.gui-title{$language} ~ " - " ~ $cfg.gui-variant;

    # set column width
    for ($output-sheet, $output-sheet-formatted) -> $sheet {
        $sheet.columns[0] = Spreadsheet::XLSX::Worksheet::Column.new:
                :custom-width, :width(20);
        $sheet.columns[1] = Spreadsheet::XLSX::Worksheet::Column.new:
                :custom-width, :width(32);
        $sheet.columns[2] = Spreadsheet::XLSX::Worksheet::Column.new:
                :custom-width, :width(20);
        $sheet.columns[3] = Spreadsheet::XLSX::Worksheet::Column.new:
                :custom-width, :width(10);
    }

    $input-sheet.columns[0] = Spreadsheet::XLSX::Worksheet::Column.new:
            :custom-width, :width(30);
    $input-sheet.columns[1] = Spreadsheet::XLSX::Worksheet::Column.new:
            :custom-width, :width(20);
    $input-sheet.columns[2] = Spreadsheet::XLSX::Worksheet::Column.new:
            :custom-width, :width(50);
    $input-sheet.columns[3] = Spreadsheet::XLSX::Worksheet::Column.new:
            :custom-width, :width(50);
    $input-sheet.columns[4] = Spreadsheet::XLSX::Worksheet::Column.new:
            :custom-width, :width(10);

    $input-sheet-formatted.columns[0] = Spreadsheet::XLSX::Worksheet::Column.new:
            :custom-width, :width(10);
    $input-sheet-formatted.columns[1] = Spreadsheet::XLSX::Worksheet::Column.new:
            :custom-width, :width(50);
    $input-sheet-formatted.columns[2] = Spreadsheet::XLSX::Worksheet::Column.new:
            :custom-width, :width(50);
    $input-sheet-formatted.columns[3] = Spreadsheet::XLSX::Worksheet::Column.new:
            :custom-width, :width(10);

    for ($output-sheet-formatted, $input-sheet-formatted) -> $sheet {
        $sheet.set(0, 0, $dataset-name, :bold);
        $sheet.set(1, 0, $user.username);
        $sheet.set(2, 0, $model-version);
        $sheet.set(3, 0, $timestamp);
    }

    for ($output-sheet, $input-sheet) -> $sheet {
        $sheet.set(0, 2, $dataset-name);
        $sheet.set(1, 2, $user.username);
        $sheet.set(2, 2, $model-version);
        $sheet.set(3, 2, $timestamp);
    }

    # prepared data
    my %data = collect-data(
        $model,
        $outputs, $inputs, $reports,
        $language, $prints,
        $include-filters, $all-filters
    );

    my @records;
    # TODO: fix sorting
    my $col = 0;
    my $row = 5;
    my $row-formatted = $row;
    my $last-print = '';
#    for @records.sort(+*.<order>) -> %rec {
    my $last-instance = '';
    my $last-module = '';
    @records := %data<inputs>;
    for @records -> %rec {

        # raw data
        $input-sheet.set($row, $col+0, %rec<gui>);
        $input-sheet.set($row, $col+1, %rec<instance>);
        $input-sheet.set($row, $col+2, %rec<input>);
        $input-sheet.set($row, $col+3, (%rec<value> // '???'), :number-format('#,#'), :horizontal-align(RightAlign));
        $input-sheet.set($row, $col+4, %rec<unit>);
        $row++;

        # formatted data
# commented out for the moment for performance reasons
#        my $instance = %rec<instance>;
#        my $module = %rec<gui>;
#        if $module ne $last-module {
#            $input-sheet-formatted.set($row-formatted, $col+0, $module, :bold);
#            $row-formatted++;
#            $last-module = $module;
#        }
#        if $instance and $instance ne $last-instance {
#            $input-sheet-formatted.set($row-formatted, $col+1, $instance, :bold);
#            $row-formatted++;
#            $last-instance = $instance;
#        }
#        $input-sheet-formatted.set($row-formatted, $col+1, %rec<input>);
#        $input-sheet-formatted.set($row-formatted, $col+2, (%rec<value-translated> // '???'), :number-format('#,#'), :horizontal-align(RightAlign));
#        $input-sheet-formatted.set($row-formatted, $col+3, %rec<unit>);
#        $row-formatted++;
    }

    # add outputs
    my %print-labels = %data<print-labels>;

    @records := %data<outputs>;
    $row = 5;
    $row-formatted = $row;
    $col = 0;
    $last-print = '';
    for @records.sort(+*.<order>) -> %rec {
        my $print = %rec<print>; # can be undefined or empty
        $output-sheet.set($row, $col+0, %print-labels{$print}{$language} // '') if $print;
        $output-sheet.set($row, $col+1, %rec<label> // 'Output: ???');
        $output-sheet.set($row, $col+2, %rec<value>, :number-format('#,###'));
        $output-sheet.set($row, $col+3, %rec<unit> // 'Unit: ???');
        $output-sheet.set($row, $col+4, %rec<order>);
        $row++;

        if $print and $print ne $last-print {
            $output-sheet-formatted.set($row-formatted, $col+0, %print-labels{$print}{$language}, :bold);
            $last-print = $print;
            $row-formatted++;
        }
        $output-sheet-formatted.set($row-formatted, $col+1, %rec<label> // 'Output: ???');
        $output-sheet-formatted.set($row-formatted, $col+2, %rec<value>, :number-format('#,###'));
        $output-sheet-formatted.set($row-formatted, $col+3, %rec<unit> // 'Unit: ???');
        $output-sheet-formatted.set($row-formatted, $col+4, %rec<order>);
        $row-formatted++;
    }
    return $workbook;
}
