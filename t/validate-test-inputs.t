use v6;
use Test;
use Data::Dump::Tree;
use Agrammon::DataSource::CSV;
use Agrammon::Model;
use Agrammon::ModelCache;
use Agrammon::Model::Parameters;
use Agrammon::OutputFormatter::CSV;
use Agrammon::OutputFormatter::JSON;
use Agrammon::OutputFormatter::Text;
use Agrammon::TechnicalParser;
use Agrammon::Validation;

my $temp-dir = $*TMPDIR.add('agrammon_testing');

for <hr-inclNOxExtendedWithFilters hr-inclNOxExtended> -> $model-version {
    subtest "Model $model-version" => {
        my $filename = $model-version ~ '-model-input.csv';
        my $fh = open $*PROGRAM.parent.add("test-data/$filename");
        my @datasets = Agrammon::DataSource::CSV.new().read($fh);
        is @datasets.elems, 1, "Got the one expected data set from $filename to run";
        my $dataset = @datasets[0];
        $fh.close;

        my $path = $*PROGRAM.parent.add("test-data/Models/$model-version/");
        my $model;
        lives-ok { $model = load-model-using-cache($temp-dir, $path, 'Total') },
                "Load module Total from $path";

        my @validation-errors;
        lives-ok { @validation-errors = validation-errors($model, $dataset) },
                'Performed validation of the inputs against the model';
        for @validation-errors -> $error {
            note $error.message;
        }
        is @validation-errors.elems, 0, 'There are no validation errors';
    }
}

done-testing;
