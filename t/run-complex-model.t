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

dd %output<Total><nh3_ntotal>;
dd %output<Total><nh3_nanimalproduction>;

note %output<Total><nh3_ntotal>;
note %output<Total><nh3_nanimalproduction>;

say %output<Total><nh3_ntotal>;
say %output<Total><nh3_nanimalproduction>;

my $nh3-ntotal = 270.851;
my $nh3-nanimalproduction = 270.851;
given $model-version {
    when   'hr-inclNOx' {
        is %output<Total><nh3_ntotal>.round(.001), $nh3-ntotal,
                "Correct nh3_ntotal result: $nh3-ntotal";
        is %output<Total><nh3_nanimalproduction>.round(.001), $nh3-nanimalproduction,
                "Correct nh3_nanimalproduction result: $nh3-nanimalproduction";
    }

    when   'hr-inclNOxExtended' {
        is %output<Total><nh3_ntotal>.round(.001), $nh3-ntotal,
                "Correct nh3_ntotal result: $nh3-ntotal";
        is %output<Total><nh3_nanimalproduction>.round(.001), $nh3-nanimalproduction,
                "Correct nh3_nanimalproduction result: $nh3-nanimalproduction";
    }
}
todo "Detailed tests for intermediate results", 1;
subtest "Intermediate results" => {
    flunk "Intermediate results ok";
}

done-testing;
