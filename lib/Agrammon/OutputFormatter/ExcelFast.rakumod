use v6;
use Agrammon::Config;
use Agrammon::Model;
use Agrammon::Outputs;
use Agrammon::OutputFormatter::CollectData;
use Agrammon::Timestamp;
use Agrammon::Web::SessionUser;
#use Spreadsheet::XLSX;
#use Spreadsheet::XLSX::Styles;

use Temp::Path;
use Excel::Writer::XLSX:from<Perl5>;

sub input-output-as-excel(
    Agrammon::Config $cfg,
    $user,
    Str $dataset-name, Agrammon::Model $model,
    Agrammon::Outputs $outputs, Agrammon::Inputs $inputs, $reports,
    Str $language, Int $report-selected,
    Bool $include-filters, Bool $all-filters
) is export {

    my $temp-file = make-temp-path :suffix<.xlsx>;
    my $workbook = Excel::Writer::XLSX.new($temp-file.absolute);
    
    # prepare sheets
    my $output-sheet = $workbook.add_worksheet('Ergebnisse');
    my $output-sheet-formatted = $workbook.add_worksheet('Ergebnisse formatiert');
    my $input-sheet = $workbook.add_worksheet('Eingaben');
    my $input-sheet-formatted = $workbook.add_worksheet('Eingaben formatiert');
    my $input-sheet-raw = $workbook.add_worksheet('Eingaben für REST');
    
    my $timestamp = timestamp;
    my $model-version = $cfg.gui-title{$language} ~ " - " ~ $cfg.gui-variant;

    # set column width
    for ($output-sheet, $output-sheet-formatted) -> $sheet {
        $sheet.set_column(0, 0, 20);
        $sheet.set_column(1, 1, 32);
        $sheet.set_column(2, 2, 20);
        $sheet.set_column(3, 3, 10);

    }

    $input-sheet.set_column(0, 0, 30);
    $input-sheet.set_column(1, 1, 20);
    $input-sheet.set_column(2, 3, 50);
    $input-sheet.set_column(4, 4, 10);

    $input-sheet-raw.set_column(0, 0, 60);
    $input-sheet-raw.set_column(1, 1, 50);
    $input-sheet-raw.set_column(2, 2, 50);

    $input-sheet-formatted.set_column(0, 0, 10);
    $input-sheet-formatted.set_column(1, 2, 50);
    $input-sheet-formatted.set_column(3, 3, 10);

    my $bold-format = $workbook.add_format();
    $bold-format.set_bold();

    my $number-format = $workbook.add_format();
    $number-format.set_num_format( '0.000' );

    my $number-format-short = $workbook.add_format();
    $number-format-short.set_num_format( '0.0' );

    my $number-format-right = $workbook.add_format();
    $number-format-right.set_num_format( '0.000' );
    $number-format-right.set_align( 'right' );

    my $number-format-right-short = $workbook.add_format();
    $number-format-right-short.set_num_format( '0.0' );
    $number-format-right-short.set_align( 'right' );

    for ($output-sheet-formatted, $input-sheet-formatted) -> $sheet {
        $sheet.write(0, 0, $dataset-name, $bold-format);
        $sheet.write(1, 0, $user.username);
        $sheet.write(2, 0, $model-version);
        $sheet.write(3, 0, $timestamp);
    }

    for ($output-sheet, $input-sheet) -> $sheet {
        $sheet.write(0, 0, $dataset-name);
        $sheet.write(1, 0, $user.username);
        $sheet.write(2, 0, $model-version);
        $sheet.write(3, 0, $timestamp);
    }
    $input-sheet-raw.write(0,0, "# $dataset-name, {$user.username}, $model-version, $timestamp");

    # prepared data
    my %data = collect-data(
        $model,
        $outputs, $inputs, $reports,
        $language, $report-selected,
        $include-filters, $all-filters
    );

    my @records;
    # TODO: fix sorting
    my $col = 0;
    my $row = 5;
    my $row-formatted = $row;
    my $row-raw = 1;
    my $last-print = '';
#    for @records.sort(+*.<order>) -> %rec {
    my $last-instance = '';
    my $last-module = '';
    @records := %data<inputs>;
    note "inputs: " ~ @records.elems if %*ENV<AGRAMMON_DEBUG>;
    for @records -> %rec {

        # unformatted data
        $input-sheet.write($row, $col+0, %rec<gui>);
        $input-sheet.write($row, $col+1, %rec<instance>);
        $input-sheet.write($row, $col+2, %rec<input-translated>);
        $input-sheet.write($row, $col+3, (%rec<value> // '???'), $number-format-right);
        $input-sheet.write($row, $col+4, %rec<unit>);
        $row++;

        # formatted data
        my $instance = %rec<instance>;
        my $module = %rec<gui>;
        if $module ne $last-module {
            $input-sheet-formatted.write($row-formatted, $col+0, $module, $bold-format);
            $row-formatted++;
            $last-module = $module;
        }
        if $instance and $instance ne $last-instance {
            $input-sheet-formatted.write($row-formatted, $col+1, $instance, $bold-format);
            $row-formatted++;
            $last-instance = $instance;
        }
        $input-sheet-formatted.write($row-formatted, $col+1, %rec<input-translated>);
        $input-sheet-formatted.write($row-formatted, $col+2, (%rec<value-translated> // '???'), $number-format-right-short);
        $input-sheet-formatted.write($row-formatted, $col+3, %rec<unit>);
        $row-formatted++;

        # raw data
        my $module-instance = %rec<module>;
        my $gui = %rec<gui>;
        if $instance {
#            note "instance=$instance, gui=$gui, module-instance=$module-instance";
            my $match = $module-instance.match(/$gui/);
            $module-instance = $match.replace-with("$gui\[$instance\]");
        }
        $input-sheet-raw.write($row-raw, $col+0, $module-instance);
        $input-sheet-raw.write($row-raw, $col+1, %rec<input>);
        $input-sheet-raw.write($row-raw, $col+2, (%rec<value> // '???'), $number-format-right);
        $row-raw++;

    }

    # add outputs
    my %print-labels = %data<print-labels>;

    @records := %data<outputs>;
    note "outputs: " ~ @records.elems if %*ENV<AGRAMMON_DEBUG>;
    $row = 5;
    $row-formatted = $row;
    $col = 0;
    $last-print = '';

    for @records.sort(+*.<order>) -> %rec {
        my $print = %rec<print>; # can be undefined or empty
        $output-sheet.write($row, $col+0, %print-labels{$print}{$language} // '') if $print;
        $output-sheet.write($row, $col+1, %rec<label> // 'Output: ???');
        $output-sheet.write($row, $col+2, %rec<value>, $number-format);
        $output-sheet.write($row, $col+3, %rec<unit> // 'Unit: ???');
        # Kept on purpose
        # $output-sheet.write($row, $col+4, %rec<order>);
        $row++;

        if $print and $print ne $last-print {
            $output-sheet-formatted.write($row-formatted, $col+0, %print-labels{$print}{$language}, $bold-format);
            $last-print = $print;
            $row-formatted++;
        }
        $output-sheet-formatted.write($row-formatted, $col+1, %rec<label> // 'Output: ???');
        $output-sheet-formatted.write($row-formatted, $col+2, %rec<value>, $number-format-short);
        $output-sheet-formatted.write($row-formatted, $col+3, %rec<unit> // 'Unit: ???');
        # Kept on purpose
        # $output-sheet-formatted.write($row-formatted, $col+4, %rec<order>);
        $row-formatted++;
    }
    $workbook.close();
    return $temp-file.slurp: :bin;
}
