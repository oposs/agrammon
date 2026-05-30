#!/usr/bin/env raku
# Clean wall-clock for the fast writer producing the full 5-sheet Agrammon-style
# report, separating workbook build (.write into the object model) from to-blob
# (string assembly + zip). Averages a few runs after one warm-up.
#
# Run:  PERL5LIB=Inline/perl5 raku -Ilib test/excel/bench-fast.raku [rows] [runs]

use v6;
use Agrammon::OutputFormatter::XLSXWriter;

my $rows = (@*ARGS[0] // 4000).Int;
my $runs = (@*ARGS[1] // 3).Int;

my @units = <kg ha LU m3 % MJ d>;
my @records = (^$rows).map(-> $i {
    %( gui => "Modul" ~ ($i div 25),
       instance => ($i %% 7 ?? '' !! "Instanz{$i div 7}"),
       input => "Eingabe-Parameter $i mit längerer Bezeichnung",
       label => "Resultat-Bezeichnung $i (NH3-N, etc.)",
       value => (($i * 7.13) % 1000) + 0.123,
       unit  => @units[$i % @units.elems],
       print => ($i %% 10 ?? "Gruppe {$i div 10}" !! ''),
    )
});

sub build-workbook(--> List) {
    my $tb = now;
    my $wb = Workbook.new;
    my $bold       = $wb.add-format(:bold);
    my $num3       = $wb.add-format(:num-format('0.000'));
    my $num1       = $wb.add-format(:num-format('0.0'));
    my $num3-right = $wb.add-format(:num-format('0.000'), :align<right>);
    my $num1-right = $wb.add-format(:num-format('0.0'),  :align<right>);

    my $os  = $wb.add-worksheet('Ergebnisse');
    my $osf = $wb.add-worksheet('Ergebnisse formatiert');
    my $is  = $wb.add-worksheet('Eingaben');
    my $isf = $wb.add-worksheet('Eingaben formatiert');
    my $isr = $wb.add-worksheet('Eingaben für REST');

    my $row = 5; my $rowf = 5; my $rowr = 1;
    my $last-instance = ''; my $last-module = '';
    for @records -> %rec {
        $is.write($row, 0, %rec<gui>); $is.write($row, 1, %rec<instance>);
        $is.write($row, 2, %rec<input>); $is.write($row, 3, %rec<value>, $num3-right);
        $is.write($row, 4, %rec<unit>); $row++;

        if %rec<gui> ne $last-module { $isf.write($rowf, 0, %rec<gui>, $bold); $rowf++; $last-module = %rec<gui> }
        if %rec<instance> && %rec<instance> ne $last-instance { $isf.write($rowf, 1, %rec<instance>, $bold); $rowf++; $last-instance = %rec<instance> }
        $isf.write($rowf, 1, %rec<input>); $isf.write($rowf, 2, %rec<value>, $num1-right);
        $isf.write($rowf, 3, %rec<unit>); $rowf++;

        $isr.write($rowr, 0, %rec<gui>); $isr.write($rowr, 1, %rec<input>);
        $isr.write($rowr, 2, %rec<value>, $num3-right); $rowr++;
    }
    $row = 5; $rowf = 5; my $last-print = '';
    for @records -> %rec {
        $os.write($row, 1, %rec<label>); $os.write($row, 2, %rec<value>, $num3);
        $os.write($row, 3, %rec<unit>); $row++;
        $osf.write($rowf, 1, %rec<label>); $osf.write($rowf, 2, %rec<value>, $num1);
        $osf.write($rowf, 3, %rec<unit>); $rowf++;
    }
    ($wb, (now - $tb).Num)
}

# warm-up
build-workbook()[0].to-blob;

my @build; my @ser;
for ^$runs {
    my ($wb, $bt) = build-workbook();
    my $ts = now;
    my $blob = $wb.to-blob;
    @ser.push: (now - $ts).Num;
    @build.push: $bt;
    LAST { say "bytes: ", $blob.bytes }
}
my $b = @build.sum / @build.elems;
my $s = @ser.sum / @ser.elems;
printf "fast writer, %d rows, %d sheets, avg of %d runs:\n", $rows, 5, $runs;
printf "  build  : %.3f s\n", $b;
printf "  to-blob: %.3f s\n", $s;
printf "  TOTAL  : %.3f s\n", $b + $s;
say "  (for reference: Spreadsheet::XLSX ~260s, Excel::Writer::XLSX ~8s at 4000 rows)";
