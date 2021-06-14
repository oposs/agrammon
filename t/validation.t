use Agrammon::DataSource::CSV;
use Agrammon::Validation;
use Test;

my $path = $*PROGRAM.parent.add('test-data/Models/validation');
my $model = Agrammon::Model.new(:$path);
lives-ok { $model.load('Test') },
        'Loaded model to use for testing validation';

my $filename = $*PROGRAM.parent.add('test-data/validation.csv');
my $fh = open $filename, :r;
my $ds = Agrammon::DataSource::CSV.new;
my @datasets = $ds.read($fh);
$fh.close;
is @datasets.elems, 10, 'Loaded datasets to validate';

subtest 'Single instance inputs with no problems' => {
    given @datasets[0] -> $dataset {
        my @validation-errors;
        lives-ok { @validation-errors = validation-errors($model, $dataset) },
                'Performed validation of the inputs against the model';
        is @validation-errors.elems, 0, 'There are no validation errors';
    }
}

subtest 'Missing inputs (single instance)' => {
    given @datasets[1] -> $dataset {
        my @validation-errors;
        lives-ok { @validation-errors = validation-errors($model, $dataset) },
                'Performed validation of the inputs against the model';
        is @validation-errors.elems, 2, 'Got two validation errors as expected';
        ok all(@validation-errors) ~~ Agrammon::Validation::MissingInput,
            'Got missing input errors as expected';
        ok all(@validation-errors).module eq 'Test', 'All have correct module';
        is @validation-errors.map(*.input).sort, <a_float a_string>,
            'Correct inputs are reported missing';
    }
}

subtest 'Inputs with no matching module or input (single instance)' => {
    given @datasets[2] -> $dataset {
        my @validation-errors;
        lives-ok { @validation-errors = validation-errors($model, $dataset) },
                'Performed validation of the inputs against the model';
        is @validation-errors.elems, 2, 'Got two validation errors as expected';
        given @validation-errors.first(Agrammon::Validation::NoSuchModule) {
            isa-ok $_, Agrammon::Validation::NoSuchModule, 'Got no such module error';
            is .module, 'Wat', 'Correct module name reported';
        }
        given @validation-errors.first(Agrammon::Validation::NoSuchInput) {
            isa-ok $_, Agrammon::Validation::NoSuchInput, 'Got no such input error';
            is .module, 'Test', 'Correct module name reported';
            is .input, 'a_bogus_input', 'Correct input name reported';
        }
    }
}

subtest 'Inputs with wrong type (single instance)' => {
    given @datasets[3] -> $dataset {
        my @validation-errors;
        lives-ok { @validation-errors = validation-errors($model, $dataset) },
                'Performed validation of the inputs against the model';
        is @validation-errors.elems, 3, 'Got 3 validation errors as expected';
        ok all(@validation-errors) ~~ Agrammon::Validation::IncorrectType,
                'All errors are about type';
        ok all(@validation-errors).module eq 'Test',
                'Errors are reported against the correct module';
        @validation-errors .= sort(*.input);
        is @validation-errors[0].input, 'a_float', 'Correct first input in validation error';
        is @validation-errors[0].expected-type, 'float', 'Correct first expected type in validation error';
        is @validation-errors[1].input, 'a_percentage', 'Correct second input in validation error';
        is @validation-errors[1].expected-type, 'percent', 'Correct second expected type in validation error';
        is @validation-errors[2].input, 'an_int', 'Correct third input in validation error';
        is @validation-errors[2].expected-type, 'integer', 'Correct third expected type in validation error';
    }
}

subtest 'Invalid enum value (single instance)' => {
    given @datasets[4] -> $dataset {
        my @validation-errors;
        lives-ok { @validation-errors = validation-errors($model, $dataset) },
                'Performed validation of the inputs against the model';
        is @validation-errors.elems, 1, 'Got one validation error as expected';
        given @validation-errors[0] {
            isa-ok $_, Agrammon::Validation::InvalidEnumValue,
                'Got invalid enum value error as expected';
            is .module, 'Test', 'Have correct module';
            is .input, 'an_enum', 'Have correct input';
            is-deeply .valid, [<first second third>], 'Have correct valid values';
        }
    }
}

subtest 'Inputs with values out of range (single instance)' => {
    given @datasets[5] -> $dataset {
        my @validation-errors;
        lives-ok { @validation-errors = validation-errors($model, $dataset) },
            'Performed validation of the inputs against the model';
        is @validation-errors.elems, 5, 'Got two validation errors as expected';
        ok all(@validation-errors) ~~ Agrammon::Validation::ValueOutOfRange,
            'All errors were value out of range errors';
        is all(@validation-errors).module, 'Test', 'Correct module in call errors';
        is-deeply @validation-errors.sort(*.input).map({ .input => .range }).hash,
            {
                with_between => 4000..15000,
                with_ge => 0..*,
                with_gt => 5.5^..*,
                with_le => *..100,
                with_lt => *..^5.5
            },
            'Correct validation ranges';
    }
}

subtest 'Multi-instance data for single-instance module' => {
    given @datasets[6] -> $dataset {
        my @validation-errors;
        lives-ok { @validation-errors = validation-errors($model, $dataset) },
                'Performed validation of the inputs against the model';
        is @validation-errors.elems, 1, 'Got one validation error as expected';
        given @validation-errors[0] {
            isa-ok $_, Agrammon::Validation::MultiInputForSingleModule,
                    'Got multiple input for single instance module error as expected';
            is .module, 'Test', 'Have correct module';
        }
    }
}

subtest 'Single-instance data for multi-instance module' => {
    given @datasets[7] -> $dataset {
        my @validation-errors;
        lives-ok { @validation-errors = validation-errors($model, $dataset) },
                'Performed validation of the inputs against the model';
        is @validation-errors.elems, 2, 'Got two validation error as expected';
        ok all(@validation-errors) ~~ Agrammon::Validation::SingleInputForMultiModule,
                'All errors complain about single instance input for multi instance modules';
        is @validation-errors.map(*.module).sort, <Test::SubModule Test::SubModule::SubTest>,
            'Correct modules are complained about';
    }
}

subtest 'Problems in multiple-instance modules with instances from one submodule' => {
    given @datasets[8] -> $dataset {
        my @validation-errors;
        lives-ok { @validation-errors = validation-errors($model, $dataset) },
                'Performed validation of the inputs against the model';
        is @validation-errors.elems, 6, 'Got six validation error as expected';
        dd @validation-errors;
        @validation-errors .= sort(*.instance);
        given @validation-errors[0] {
            isa-ok $_, Agrammon::Validation::InvalidEnumValue,
                'Got an invalid enum error';
            is .module, 'Test::SubModule::SubTest', 'It is on the correct module';
            is .instance, 'Instance 2', 'It is on the correct instance';
        }
        given @validation-errors[1] {
            isa-ok $_, Agrammon::Validation::ValueOutOfRange,
                    'Got a value out of range error';
            is .module, 'Test::SubModule', 'It is on the correct module';
            is .instance, 'Instance 3', 'It is on the correct instance';
        }
        given @validation-errors[2] {
            isa-ok $_, Agrammon::Validation::IncorrectType,
                    'Got an incorrect type error';
            is .module, 'Test::SubModule', 'It is on the correct module';
            is .instance, 'Instance 4', 'It is on the correct instance';
        }
        given @validation-errors[3] {
            isa-ok $_, Agrammon::Validation::MissingInput,
                    'Got an missing input error';
            is .module, 'Test::SubModule::SubTest', 'It is on the correct module';
            is .instance, 'Instance 5', 'It is on the correct instance';
            is .input, 'an_enum', 'It complains about the correct missing input';
        }
        given @validation-errors[4] {
            isa-ok $_, Agrammon::Validation::NoSuchInput,
                    'Got a no such input error';
            is .module, 'Test::SubModule', 'It is on the correct module';
            is .instance, 'Instance 6', 'It is on the correct instance';
            is .input, 'a_non_existing', 'It identifies the correct input';
        }
        given @validation-errors[5] {
            isa-ok $_, Agrammon::Validation::NoSuchModule,
                    'Got a no such module error';
            is .module, 'Test::SubModule::Who', 'It is on the correct module';
        }
    }
}

subtest 'No problems in multiple-instance modules with instances from two submodules' => {
    given @datasets[9] -> $dataset {
        my @validation-errors;
        lives-ok { @validation-errors = validation-errors($model, $dataset) },
                'Performed validation of the inputs against the model';
        
        is @validation-errors.elems, 0, 'Got no validation errors as expected'
           or diag dd @validation-errors;
    }
}

done-testing;
