use Agrammon::Formula::Builtins;
use Agrammon::Outputs;

class Agrammon::Environment {
    has $.input;
    has $.technical;
    has Agrammon::Outputs::SingleOutputStorage $.output;
    has %.builtins;

    method find-builtin($name) {
        %!builtins{$name} // get-builtins(){$name} // die "No such builtin function '$name'";
    }
}
