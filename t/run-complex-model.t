use Test;
use Agrammon::DataSource::CSV;
use Agrammon::Model;
use Agrammon::Model::Parameters;
use Agrammon::OutputFormatter::CSV;
use Agrammon::TechnicalParser;

my $model-version = 'hr-inclNOxExtended';
my $path = $*PROGRAM.parent.add("test-data/Models/$model-version/");
my $model = Agrammon::Model.new(:$path);
lives-ok { $model.load('End') }, "Could load module End from $path";

my $fh = open $*PROGRAM.parent.add('test-data/complex-model-input.csv');
my @datasets = Agrammon::DataSource::CSV.new().read($fh);
is @datasets.elems, 1, 'Got the one expected data set to run';
$fh.close;

my $params;
lives-ok
    { $params = parse-technical($*PROGRAM.parent.add("test-data/Models/$model-version/technical.cfg").slurp) },
    'Parsed technical file';
isa-ok $params, Agrammon::Model::Parameters, 'Correct type for technical data';

my %output;
lives-ok
    {
        %output = $model.run(
            input => @datasets[0],
            technical => %($params.technical.map(-> %module {
                %module.keys[0] => %(%module.values[0].map({ .name => .value }))
            }))
        ).get-outputs-hash()
    },
    'Successfully executed model';

#dd %output<Total><nh3_ntotal>;
#dd %output<Total><nh3_nanimalproduction>;

given $model-version {
    when   'hr-inclNOx' {
        is %output<Total><nh3_ntotal>, <1034973404862461426773/2623437500000000000>,
                "Correct nh3_ntotal result: %output<Total><nh3_ntotal>";
        is %output<Total><nh3_nanimalproduction>, <764444529862461426773/2623437500000000000>,
                "Correct nh3_nanimalproduction result: %output<Total><nh3_nanimalproduction>";
    }

    when   'hr-inclNOxExtended' {
        is %output<Total><nh3_ntotal>, <2831516334992619272501/10493750000000000000>,
                "Correct nh3_ntotal result: %output<Total><nh3_ntotal>";
        is %output<Total><nh3_nanimalproduction>, <2831516334992619272501/10493750000000000000>,
                "Correct nh3_nanimalproduction result: %output<Total><nh3_nanimalproduction>";
    }
}
todo "Detailed tests for intermediate results", 1;
subtest "Intermediate results" => {
    flunk "Intermediate results ok";
}

done-testing;
