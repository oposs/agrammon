#!/usr/bin/env raku
# Generate a sample .xlsx with the new fast string writer, laid out exactly like
# Agrammon's production Excel export (ExcelFast.rakumod): the same 5 sheets, sheet
# names, column widths, header block, bold headers, number formats and right
# alignment — but with synthetic data — so the result can be opened in Excel /
# LibreOffice and compared visually with a real Agrammon export.
#
# Run:  PERL5LIB=Inline/perl5 raku -Ilib test/excel/gen-fast.raku [rows] [out.xlsx]

use v6;
use Agrammon::OutputFormatter::XLSXWriter;

my $rows = (@*ARGS[0] // 300).Int;
my $out  = @*ARGS[1] // 'test/excel/sample-fast.xlsx';

my $dataset-name = 'Beispielbetrieb 2026';
my $username     = 'demo.user';
my $model-version = 'Agrammon 7.0.0 - SHL';
my $timestamp    = '2026-05-30 12:00:00';

# synthetic, representative records (stand-ins for collect-data rows)
my @units = <kg ha LU m3 % MJ d>;
my @records = (^$rows).map(-> $i {
    %(
        gui       => "Modul" ~ ($i div 25),
        instance  => ($i %% 7 ?? '' !! "Instanz{$i div 7}"),
        input     => "Eingabe-Parameter $i mit längerer Bezeichnung",
        label     => "Resultat-Bezeichnung $i (NH3-N, etc.)",
        value     => (($i * 7.13) % 1000) + 0.123,
        unit      => @units[$i % @units.elems],
        print     => ($i %% 10 ?? "Gruppe {$i div 10}" !! ''),
    )
});

my $t0 = now;

my $wb = Workbook.new;

# formats (registered once, referenced by index)
my $bold      = $wb.add-format(:bold);
my $num3      = $wb.add-format(:num-format('0.000'));
my $num1      = $wb.add-format(:num-format('0.0'));
my $num3-right = $wb.add-format(:num-format('0.000'), :align<right>);
my $num1-right = $wb.add-format(:num-format('0.0'),  :align<right>);

# --- sheets ---
my $output-sheet           = $wb.add-worksheet('Ergebnisse');
my $output-sheet-formatted = $wb.add-worksheet('Ergebnisse formatiert');
my $input-sheet            = $wb.add-worksheet('Eingaben');
my $input-sheet-formatted  = $wb.add-worksheet('Eingaben formatiert');
my $input-sheet-raw        = $wb.add-worksheet('Eingaben für REST');

# column widths (same as ExcelFast.rakumod)
for ($output-sheet, $output-sheet-formatted) -> $s {
    $s.set-column(0, 20); $s.set-column(1, 32);
    $s.set-column(2, 20); $s.set-column(3, 10);
}
$input-sheet.set-column(0, 30); $input-sheet.set-column(1, 20);
$input-sheet.set-column(2, 50); $input-sheet.set-column(3, 50); $input-sheet.set-column(4, 10);
$input-sheet-raw.set-column(0, 60); $input-sheet-raw.set-column(1, 50); $input-sheet-raw.set-column(2, 50);
$input-sheet-formatted.set-column(0, 10); $input-sheet-formatted.set-column(1, 50);
$input-sheet-formatted.set-column(2, 50); $input-sheet-formatted.set-column(3, 10);

# header blocks
for ($output-sheet-formatted, $input-sheet-formatted) -> $s {
    $s.write(0, 0, $dataset-name, $bold);
    $s.write(1, 0, $username);
    $s.write(2, 0, $model-version);
    $s.write(3, 0, $timestamp);
}
for ($output-sheet, $input-sheet) -> $s {
    $s.write(0, 0, $dataset-name);
    $s.write(1, 0, $username);
    $s.write(2, 0, $model-version);
    $s.write(3, 0, $timestamp);
}
$input-sheet-raw.write(0, 0, "# $dataset-name, $username, $model-version, $timestamp");

# --- inputs ---
my $row = 5;
my $row-formatted = 5;
my $row-raw = 1;
my $last-instance = '';
my $last-module = '';
for @records -> %rec {
    # raw / unformatted
    $input-sheet.write($row, 0, %rec<gui>);
    $input-sheet.write($row, 1, %rec<instance>);
    $input-sheet.write($row, 2, %rec<input>);
    $input-sheet.write($row, 3, %rec<value>, $num3-right);
    $input-sheet.write($row, 4, %rec<unit>);
    $row++;

    # formatted with bold module / instance headers
    my $instance = %rec<instance>;
    my $module   = %rec<gui>;
    if $module ne $last-module {
        $input-sheet-formatted.write($row-formatted, 0, $module, $bold);
        $row-formatted++; $last-module = $module;
    }
    if $instance && $instance ne $last-instance {
        $input-sheet-formatted.write($row-formatted, 1, $instance, $bold);
        $row-formatted++; $last-instance = $instance;
    }
    $input-sheet-formatted.write($row-formatted, 1, %rec<input>);
    $input-sheet-formatted.write($row-formatted, 2, %rec<value>, $num1-right);
    $input-sheet-formatted.write($row-formatted, 3, %rec<unit>);
    $row-formatted++;

    # REST raw sheet
    $input-sheet-raw.write($row-raw, 0, %rec<gui> ~ ($instance ?? "[$instance]" !! ''));
    $input-sheet-raw.write($row-raw, 1, %rec<input>);
    $input-sheet-raw.write($row-raw, 2, %rec<value>, $num3-right);
    $row-raw++;
}

# --- outputs ---
$row = 5; $row-formatted = 5;
my $last-print = '';
for @records -> %rec {
    my $print = %rec<print>;
    $output-sheet.write($row, 0, $print) if $print;
    $output-sheet.write($row, 1, %rec<label>);
    $output-sheet.write($row, 2, %rec<value>, $num3);
    $output-sheet.write($row, 3, %rec<unit>);
    $row++;

    if $print && $print ne $last-print {
        $output-sheet-formatted.write($row-formatted, 0, $print, $bold);
        $last-print = $print; $row-formatted++;
    }
    $output-sheet-formatted.write($row-formatted, 1, %rec<label>);
    $output-sheet-formatted.write($row-formatted, 2, %rec<value>, $num1);
    $output-sheet-formatted.write($row-formatted, 3, %rec<unit>);
    $row-formatted++;
}

my $blob = $wb.to-blob;
$out.IO.spurt: $blob;

my $dt = (now - $t0).Num;
printf "wrote %s : %d rows, %d sheets, %d bytes in %.3f s\n",
    $out, $rows, 5, $blob.bytes, $dt;
