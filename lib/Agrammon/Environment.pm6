use v6;
use Agrammon::Formula::Builtins;
use Agrammon::Outputs;

class Agrammon::Environment {
    has $.input;
    has $.technical;
    has $.technical-override;
    has Agrammon::Outputs::SingleOutputStorage $.output;
    has %.builtins;

    method get-input($name) {
        $!input{$name}
    }

    method get-technical($name) {
        $!technical-override{$name} // $!technical{$name}
    }

    method find-builtin($name) {
        %!builtins{$name} // get-builtins(){$name} // die "No such builtin function '$name'";
    }
}
