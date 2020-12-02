use v6;
use Agrammon::DataSource::CSV;
use Agrammon::Model;
use Agrammon::ModelCache;
use Agrammon::Model::Parameters;
use Agrammon::OutputFormatter::CSV;
use Agrammon::TechnicalParser;
use Shell::Command;
use Test;

my $temp-dir = $*TMPDIR.add(('A'..'Z').roll(20).join);
mkdir $temp-dir;
END rm_rf $temp-dir;

my $path = $*PROGRAM.parent.add('test-data/Models/hr-inclNOx/');
my $model;

lives-ok { $model = load-model-using-cache($temp-dir, $path, 'Total') },
        'Can load model via the cache';
isa-ok $model, Agrammon::Model, 'Loaded model has correct type';

lives-ok { $model = load-model-using-cache($temp-dir, $path, 'Total') },
        'Can load model via the cache a second time';
isa-ok $model, Agrammon::Model, 'Loaded again model has correct type';

my $fh = open $*PROGRAM.parent.add('test-data/complex-model-input.csv');
my @datasets = Agrammon::DataSource::CSV.new().read($fh);
is @datasets.elems, 1, 'Got the one expected data set to run';
$fh.close;

my $params= parse-technical($*PROGRAM.parent.add('test-data/Models/hr-inclNOx/technical.cfg').slurp);

lives-ok
    {
        $model.run(
            input => @datasets[0],
            technical => %($params.technical.map(-> %module {
                %module.keys[0] => %(%module.values[0].map({ .name => .value }))
            }))
        )
    },
    'Successfully executed model loaded from cache';

done-testing;
