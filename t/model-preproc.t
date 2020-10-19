use Agrammon::Model;
use Test;

subtest 'With no preprocessor options specified' => {
    my $path = $*PROGRAM.parent.add('test-data/Models/preproc/');
    my $model = Agrammon::Model.new(:$path);
    lives-ok { $model.load('Preproc') }, 'Can load preproc module';
    my Agrammon::Model::Module $module = $model.evaluation-order[0];
    is $module.input[0].enum.elems, 2,
            'With no preproc options specified, only 2 enum elements';
}

subtest 'With preprocessor option enabled' => {
    my $path = $*PROGRAM.parent.add('test-data/Models/preproc/');
    my $model = Agrammon::Model.new(:$path, :preprocessor-options{ :HORSISH });
    lives-ok { $model.load('Preproc') }, 'Can load preproc module';
    my Agrammon::Model::Module $module = $model.evaluation-order[0];
    is $module.input[0].enum.elems, 4,
            'With preproc option specified, have all 4 enum elements';
}

done-testing;
