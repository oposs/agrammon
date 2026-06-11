use v6;
use Agrammon::Config;
use Agrammon::Model;
use Agrammon::Outputs;
use Agrammon::OutputFormatter::CollectData;
use Agrammon::Timestamp;
use Agrammon::Web::SessionUser;
use Agrammon::OutputFormatter::XLSXWriter;

# Native (pure-Raku) Excel exporter. Provides `input-output-as-excel` and the
# Agrammon workbook layout (5 sheets, column widths, header block, bold
# module/group headers, 0.000/0.0 number formats, right-aligned values),
# produced with Agrammon::OutputFormatter::XLSXWriter (string-built XLSX, no
# LibXML DOM and no Excel::Writer::XLSX / Inline::Perl5 round-trip).
#
# On a realistic 4000-row report this is ~3.5x faster than the Perl path and
# ~110x faster than the Spreadsheet::XLSX (LibXML) path. See test/excel/FINDINGS.md.

sub input-output-as-excel(
    Agrammon::Config $cfg,
    $user,
    Str $dataset-name, Agrammon::Model $model,
    Agrammon::Outputs $outputs, Agrammon::Inputs $inputs, $reports,
    Str $language, Int $report-selected,
    Bool $include-filters, Bool $all-filters
) is export {

    my $workbook = Workbook.new;

    # prepare sheets
    my $output-sheet           = $workbook.add-worksheet('Ergebnisse');
    my $output-sheet-formatted = $workbook.add-worksheet('Ergebnisse formatiert');
    my $input-sheet            = $workbook.add-worksheet('Eingaben');
    my $input-sheet-formatted  = $workbook.add-worksheet('Eingaben formatiert');
    my $input-sheet-raw        = $workbook.add-worksheet('Eingaben für REST');

    my $timestamp = timestamp;
    my $model-version = $cfg.gui-title{$language} ~ " - " ~ $cfg.gui-variant;

    # set column width (helper expands the inclusive [first, last] ranges that
    # Excel::Writer::XLSX.set_column accepts onto our single-column setter)
    sub set-cols($sheet, Int $first, Int $last, Real $width) {
        $sheet.set-column($_, $width) for $first .. $last;
    }

    for ($output-sheet, $output-sheet-formatted) -> $sheet {
        set-cols($sheet, 0, 0, 20);
        set-cols($sheet, 1, 1, 32);
        set-cols($sheet, 2, 2, 20);
        set-cols($sheet, 3, 3, 10);
    }

    set-cols($input-sheet, 0, 0, 30);
    set-cols($input-sheet, 1, 1, 20);
    set-cols($input-sheet, 2, 3, 50);
    set-cols($input-sheet, 4, 4, 10);

    set-cols($input-sheet-raw, 0, 0, 60);
    set-cols($input-sheet-raw, 1, 1, 50);
    set-cols($input-sheet-raw, 2, 2, 50);

    set-cols($input-sheet-formatted, 0, 0, 10);
    set-cols($input-sheet-formatted, 1, 2, 50);
    set-cols($input-sheet-formatted, 3, 3, 10);

    my $bold-format               = $workbook.add-format(:bold);
    my $number-format             = $workbook.add-format(:num-format('0.000'));
    my $number-format-short       = $workbook.add-format(:num-format('0.0'));
    my $number-format-right       = $workbook.add-format(:num-format('0.000'), :align<right>);
    my $number-format-right-short = $workbook.add-format(:num-format('0.0'),  :align<right>);

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
    $input-sheet-raw.write(0, 0, "# $dataset-name, {$user.username}, $model-version, $timestamp");

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
        $row++;

        if $print and $print ne $last-print {
            $output-sheet-formatted.write($row-formatted, $col+0, %print-labels{$print}{$language}, $bold-format);
            $last-print = $print;
            $row-formatted++;
        }
        $output-sheet-formatted.write($row-formatted, $col+1, %rec<label> // 'Output: ???');
        $output-sheet-formatted.write($row-formatted, $col+2, %rec<value>, $number-format-short);
        $output-sheet-formatted.write($row-formatted, $col+3, %rec<unit> // 'Unit: ???');
        $row-formatted++;
    }

    return $workbook.to-blob;
}
