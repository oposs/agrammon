use v6;
use Agrammon::DataSource::CSV;
use Test;

my $filename = 't/test-data/inputPlantproduction.csv';
my $datasetsExpected = 2;
my $elementsExpected = 6;

my $fh = open $filename, :r, chomp => False
            or die "Couldn't open file $filename for reading";

my $ds = Agrammon::DataSource::CSV.new;
isa-ok $ds, Agrammon::DataSource::CSV, 'Is a DataSource::CSV';

my \datasets = $ds.read($fh);
ok datasets, 'Agrammon::DataSource::CSV.read() found datasets';

my $n = 0;
for datasets -> @data {
    $n++;
    is @data.elems,  $elementsExpected, "Dataset $n has  $elementsExpected elements";
}
is $n, 2, "Found $datasetsExpected datasets";

done-testing;
    
