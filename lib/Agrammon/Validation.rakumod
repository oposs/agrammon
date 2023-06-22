unit module Agrammon::Validation;
use Agrammon::Inputs;
use Agrammon::Model;

#| The root of all validation problems found.
role Problem {
    #| The module where the problem was found.
    has Str $.module is required;
}

#| An input value for a module that doesn't exist at all.
class NoSuchModule does Problem {
    #| The instance, if any.
    has Str $.instance;

    method message() {
        "Input for module '$!module'" ~
                ($!instance ?? " of instance $!instance" !! "") ~
                ", but no such module exists in the model"
    }
}

#| Multi-instance input for single-instance module.
class MultiInputForSingleModule does Problem {
    method message() {
        "Input with instance for module '$!module', which is a single-instance module"
    }
}

#| Single-instance input for multi-instance module.
class SingleInputForMultiModule does Problem {
    method message() {
        "Input without instance for module '$!module', which is a multi-instance module"
    }
}

#| The root of all problems concerning a particular input.
role InputProblem does Problem {
    #| The instance, if any.
    has Str $.instance;

    #| The input that the problem relates to.
    has Str $.input is required;

    method !prefix() {
        "Input '$!input' in '$.module' " ~ ($!instance ?? "instance '$!instance' " !! "")
    }
}

#| An input value for an input that does not exist.
class NoSuchInput does InputProblem {
    method message() {
        self!prefix() ~ "does not exist in the model"
    }
}

#| A missing required input.
class MissingInput does InputProblem {
    method message() {
        self!prefix() ~ "is missing"
    }
}

#| An input that is not of the correct type.
class IncorrectType does InputProblem {
    #| The expected type.
    has Str $.expected-type is required;

    #| The actual value.
    has Any $.value is required;

    method message() {
        self!prefix() ~ " should be of type $!expected-type, but got value '$!value'"
    }
}

#| An input for an enum type that has a value not valid for the enum.
class InvalidEnumValue does InputProblem {
    #| The valid enum values.
    has @.valid is required;

    #| The actual value.
    has Any $.value is required;

    method message() {
        self!prefix() ~ " has value '$!value', which is not in the enum: " ~
                @!valid.map({ "'$_'" }).join(",")
    }
}

#| An input for a numeric type is out of range.
class ValueOutOfRange does InputProblem {
    #| The valid range.
    has Range $.range is required;

    #| The actual value.
    has Any $.value is required;

    method message() {
        self!prefix() ~ " has value '$!value', which is not in the range $!range.raku()"
    }
}

#| Validate the provided inputs against the model. Returns a list of validation
#| errors; if there are no problems, the list will be empty.
sub validation-errors(Agrammon::Model $model, Agrammon::Inputs $inputs --> List) is export {
    # Obtain model structure and inputs to check. We will proceed by removing checked
    # inputs from the hash, so those left over at the end are inputs for modules that
    # do not exist.
    my @model-structure := $model.extract-structure;
    my %inputs-to-check = $inputs.all-inputs;

    # We'll collect all problems into an array. First, go through the model structure.
    my @problems;
    for @model-structure {
        when Str {
            # Single instance module
            my $input = %inputs-to-check{$_}:delete;
            if $input ~~ Hash {
                check-module-inputs($model.get-module($_), $input, @problems);
            }
            elsif $input ~~ List {
                @problems.push: MultiInputForSingleModule.new(:module($_));
            }
        }
        when Pair {
            # Multi-instance module
            my $entrypoint = .key;
            my @modules = @(.value);
            my $instances = %inputs-to-check{$entrypoint};
            if $instances ~~ List {
                # Go over the instances and check them.
                for @$instances -> Pair $instance-data {
                    my $instance = $instance-data.key;
                    my %instance-input := $instance-data.value;
                    for @modules -> $module {
                        my %input := %instance-input{$module}:delete // {};
                        check-module-inputs($model.get-module($module), %input, @problems, :$instance);
                    }
                    @problems.append: %instance-input.keys.map: { NoSuchModule.new(:$^module, :$instance) }
                }
                %inputs-to-check{$entrypoint}:delete;
            }
            else {
                # Report errors for all single-instance input data for multi modules in
                # this part of the graph.
                for @modules -> $module {
                    if %inputs-to-check{$module}:delete ~~ Map {
                        @problems.push: SingleInputForMultiModule.new(:$module);
                    }
                }
            }
        }
    }

    # Report bogus modules.
    @problems.append: %inputs-to-check.keys.map: { NoSuchModule.new(:$^module) }

    return @problems;
}

sub check-module-inputs(Agrammon::Model::Module $module, %inputs is copy, @problems, Str :$instance --> Nil) {
    # Check the inputs we have.
    for $module.input -> $input {
        with %inputs{$input.name}:delete -> $value {
            given $input.type {
                when /integer|float|percent/ {
                    return if $value eq 'Standard';
                }
            }
            given $input.type {
                when 'integer' {
                    if $value ~~ Int {
                        check-range($module, $input, $instance, $value, @problems);
                    }
                    else {
                        report-invalid-type($module, $input, $instance, $value, @problems);
                    }
                }
                when 'float' {
                    if $value ~~ Real {
                        check-range($module, $input, $instance, $value, @problems);
                    }
                    else {
                        report-invalid-type($module, $input, $instance, $value, @problems);
                    }
                }
                when 'percent' {
                    if $value ~~ Real && 0 <= $value <= 100 {
                        check-range($module, $input, $instance, $value, @problems);
                    }
                    else {
                        report-invalid-type($module, $input, $instance, $value, @problems);
                    }
                }
                when 'enum' {
                    unless $input.is-valid-enum-value($value) {
                        @problems.push: InvalidEnumValue.new: :module($module.taxonomy), :$instance,
                                :input($input.name), :valid($input.enum-ordered.map(*.key)), :$value;
                    }
                }
                when 'text' {
                    # Nothing to check
                }
                default {
                    warn "Unknown input type in validation: $_";
                }
            }
        }
        else {
            without $input.default-calc orelse $input.default-formula {
                @problems.push: MissingInput.new(:module($module.taxonomy), :$instance, :input($input.name));
            }
        }
    }

    # Report unexpected inputs.
    @problems.append: %inputs.keys.map: {
        NoSuchInput.new(:module($module.taxonomy), :$instance, :$^input)
    }
}

sub report-invalid-type(Agrammon::Model::Module $module, Agrammon::Model::Input $input,
                        Str $instance, Any $value, @problems --> Nil) {
    @problems.push: IncorrectType.new: :module($module.taxonomy), :$instance,
            :input($input.name), :expected-type($input.type), :$value;
}

my regex number { '-'? \d+ ['.' \d+ ]? }

sub check-range(Agrammon::Model::Module $module, Agrammon::Model::Input $input,
                Str $instance, Real $value, @problems --> Nil) {
    my $validator = $input.validator;
    return unless $validator;
    my $range = do given $validator {
        when /:s ^ 'between' '(' <from=&number> ',' <to=&number> ')' ';'? $/ {
            +$<from> .. +$<to>
        }
        when /:s ^ 'ge' '(' <number> ')' ';'? $/ { +$<number> .. *  }
        when /:s ^ 'gt' '(' <number> ')' ';'? $/ { +$<number> ^.. *  }
        when /:s ^ 'le' '(' <number> ')' ';'? $/ { * .. +$<number> }
        when /:s ^ 'lt' '(' <number> ')' ';'? $/ { * ..^ +$<number> }
        default {
            warn "Unknown validator '$_'";
            return;
        }
    }
    if $value !~~ $range {
        @problems.push: ValueOutOfRange.new: :module($module.taxonomy), :$instance,
            :input($input.name), :$range, :$value;
    }
}
