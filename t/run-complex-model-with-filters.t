use Test;
use Data::Dump::Tree;
use Agrammon::DataSource::CSV;
use Agrammon::Model;
use Agrammon::Model::Parameters;
use Agrammon::OutputFormatter::CSV;
use Agrammon::OutputFormatter::GUI;
use Agrammon::OutputFormatter::Text;
use Agrammon::TechnicalParser;

my $model-version = 'hr-inclNOxExtendedWithFilters';
my $path = $*PROGRAM.parent.add("test-data/Models/$model-version/");
my $model = Agrammon::Model.new(:$path);
lives-ok { $model.load('End') }, "Load module End.nhd from $path";

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

#dd %output<Total><nh3_ntotal>;
#dd %output<Total><nh3_nanimalproduction>;
my $nh3-ntotal = 2948.7161903612955;
my $nh3-nanimalproduction = 2948.7161903612955;

is %output-hash<Total><nh3_ntotal>, $nh3-ntotal,
        "Correct nh3_ntotal result: %output-hash<Total><nh3_ntotal>";
is %output-hash<Total><nh3_nanimalproduction>, $nh3-nanimalproduction,
        "Correct nh3_nanimalproduction result: %output-hash<Total><nh3_nanimalproduction>";

# my @instances = $output.find-instances('Livestock::Pig').sort(*.key).map(*.value);
# dd @instances;

# say "\nFluxSummaryLivestock=\n", output-as-text($model, $output, 'de', 'FluxSummaryLivestock,TANFlux', False);
say "\nFluxSummaryLivestock (Details)=\n", output-as-text($model, $output, 'de', 'FluxSummaryLivestock,TANFlux', True);

# ddt "GUI: FluxSummaryLivestock=", output-for-gui($model, $output)<data>[0];

#todo "Detailed tests for intermediate results", 1;
#subtest "Intermediate results" => {
#    flunk "Intermediate results ok";
#}

done-testing;
