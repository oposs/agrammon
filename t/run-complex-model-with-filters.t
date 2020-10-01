use Test;
use Data::Dump::Tree;
use Agrammon::DataSource::CSV;
use Agrammon::Model;
use Agrammon::ModelCache;
use Agrammon::Model::Parameters;
use Agrammon::OutputFormatter::CSV;
use Agrammon::OutputFormatter::GUI;
use Agrammon::OutputFormatter::Text;
use Agrammon::TechnicalParser;

my $temp-dir = $*TMPDIR.add('agrammon_testing');

my $model-version = 'hr-inclNOxExtendedWithFilters';
my $path = $*PROGRAM.parent.add("test-data/Models/$model-version/");
my $model;
lives-ok { $model = load-model-using-cache($temp-dir, $path, 'End') },
        "Load module End.nhd from $path";

# pigs and no dairy cows
#my $filename = 'complex-model-with-filters-input1.csv';
# no pigs, no dairy cows
# my $filename = 'complex-model-with-filters-input2.csv';
# dairy cows, no pigs
#my $filename = 'complex-model-with-filters-input3.csv';

# dairy cows and pigs
my $filename = 'complex-model-with-filters-input4.csv';

# missing animalcategory for dairy cows => warnings
#my $filename = 'complex-model-with-filters-input.csv';

my $fh = open $*PROGRAM.parent.add("test-data/$filename");
my @datasets = Agrammon::DataSource::CSV.new().read($fh);
is @datasets.elems, 1, "Got the one expected data set from $filename to run";
$fh.close;

my $params;
lives-ok
    { $params = parse-technical($*PROGRAM.parent.add("test-data/Models/$model-version/technical.cfg").slurp) },
    'Parsed technical file';
isa-ok $params, Agrammon::Model::Parameters, 'Correct type for technical data';

my $output;
lives-ok
    {
        $output = $model.run(
            input => @datasets[0],
            technical => %($params.technical.map(-> %module {
                %module.keys[0] => %(%module.values[0].map({ .name => .value }))
            }))
        )
    },
    'Successfully executed model';

my %output-hash = $output.get-outputs-hash;

my $nh3-ntotal = 2948.7161903612955;
my $nh3-nanimalproduction = 2948.7161903612955;
my $nh3-napplication = 1311.7830090654595;

is %output-hash<Total><nh3_ntotal>, $nh3-ntotal,
        "Correct nh3_ntotal result: %output-hash<Total><nh3_ntotal>";
is %output-hash<Total><nh3_nanimalproduction>, $nh3-nanimalproduction,
        "Correct nh3_nanimalproduction result: %output-hash<Total><nh3_nanimalproduction>";

is +%output-hash<Application><nh3_napplication>, $nh3-napplication,
        "Correct nh3_napplication result: {+%output-hash<Application><nh3_napplication>}";

# say "\nFluxSummaryLivestock=\n", output-as-text($model, $output, 'de', 'FluxSummaryLivestock,TANFlux', False);
#say "\nFluxSummaryLivestock (Details)=\n", output-as-text($model, $output, 'de', 'FluxSummaryLivestock,TANFlux', True);
say "\nLivestockSummary (Details)=\n", output-as-text($model, $output, 'de', 'LivestockSummary', True);

# ddt "GUI: FluxSummaryLivestock=", output-for-gui($model, $output)<data>[0];

done-testing;
