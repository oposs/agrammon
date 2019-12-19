use Agrammon::Model;
use Test;

my $path = $*PROGRAM.parent.add('test-data/Models/with-filters');
my $model = Agrammon::Model.new(:$path);
lives-ok { $model.load('End', :!compile-formulas) },
        'Can load a set of modules that makes use of filter inputs';

subtest 'We know if an input is declared as being a filter or not' => {
    given $model.evaluation-order.first(*.taxonomy eq 'Livestock::Pig::Excretion') -> $excretion {
        isa-ok $excretion, Agrammon::Model::Module, 'Found pig excretion module';
        given $excretion.input.first(*.name eq 'animalcategory') -> $input {
            isa-ok $input, Agrammon::Model::Input, 'Found animal category input';
            ok $input.is-filter, 'We filter on this input';
        }
        given $excretion.input.first(*.name eq 'pigs') -> $input {
            isa-ok $input, Agrammon::Model::Input, 'Found pigs input';
            nok $input.is-filter, 'We do not filter on this input';
        }
    }
}

done-testing;
