use v6;
use Agrammon::Formula::Builtins;
use Agrammon::Outputs;

class Agrammon::Environment {
    has $.input;
    has $.technical;
    has $.taxonomy;
    has Agrammon::Outputs::SingleOutputStorage $.output;
    has %.builtins;

    method get-input($name) {
        $!input{$name}
    }

    method get-technical($name) {
        $!technical{$name} //
            die "No value for technical parameter '$name'"
                ~ ($!taxonomy ?? " in module '$!taxonomy'" !! '')
                ~ ". Technical parameter values must be defined in technical.cfg.";
    }

    method find-builtin($name) {
        %!builtins{$name} // get-builtins(){$name} // die "No such builtin function '$name'";
    }

    method iterate($value) {
        $value ~~ Map ?? $value.kv !! $value.list
    }
}
