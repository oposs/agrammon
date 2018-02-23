use Agrammon::Environment;
use Agrammon::OutputReference;

role Agrammon::Formula {
    method evaluate(Agrammon::Environment --> Any) { ... }
    method input-used(--> List) { ... }
    method technical-used(--> List) { ... }
    method output-used(--> List) { ... }
}

class Agrammon::Formula::In does Agrammon::Formula {
    has $.symbol;

    method evaluate(Agrammon::Environment $env) {
        $env.input{$!symbol}
    }

    method input-used() { ($!symbol,) }
    method technical-used() { () }
    method output-used() { () }
}

class Agrammon::Formula::Tech does Agrammon::Formula {
    has $.symbol;

    method evaluate(Agrammon::Environment $env) {
        $env.technical{$!symbol}
    }

    method input-used() { () }
    method technical-used() { ($!symbol,) }
    method output-used() { () }
}

class Agrammon::Formula::Val does Agrammon::Formula {
    has Agrammon::OutputReference $.reference;

    method evaluate(Agrammon::Environment $env) {
        $env.output{$!reference.module}{$!reference.symbol}
    }

    method input-used() { () }
    method technical-used() { () }
    method output-used() { ($!reference,) }
}
