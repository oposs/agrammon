use Agrammon::Environment;
use Agrammon::OutputReference;

role Agrammon::Formula {
    method evaluate(Agrammon::Environment --> Any) { ... }
    method input-used(--> List) { () }
    method technical-used(--> List) { () }
    method output-used(--> List) { () }

    method !merge-inputs(*@merge) {
        list unique @merge
    }

    method !merge-technicals(*@merge) {
        list unique @merge
    }

    method !merge-outputs(*@merge) {
        list unique :by{ .module ~ '::' ~ .symbol }, @merge
    }
}

role Agrammon::Formula::LValue does Agrammon::Formula {
    # Just a marker role for l-values (things that can be assigned to)
}

class Agrammon::Formula::StatementList does Agrammon::Formula {
    has Agrammon::Formula @.statements;

    method evaluate(Agrammon::Environment $env) {
        my $result;
        for @!statements {
            $result = .evaluate($env);
        }
        return $result;
    }

    method input-used() {
        self!merge-inputs: @!statements.map(*.input-used)
    }

    method technical-used() {
        self!merge-technicals: @!statements.map(*.technical-used)
    }

    method output-used() {
        self!merge-outputs: @!statements.map(*.output-used)
    }
}

class Agrammon::Formula::If does Agrammon::Formula {
    has Agrammon::Formula $.condition;
    has Agrammon::Formula $.then;
    has Agrammon::Formula $.else;

    method input-used() {
        self!merge-inputs: $!condition.input-used, $!then.input-used,
            ($!else ?? $!else.input-used !! Empty)
    }

    method technical-used() {
        self!merge-technicals: $!condition.technical-used, $!then.technical-used,
            ($!else ?? $!else.technical-used !! Empty)
    }

    method output-used() {
        self!merge-outputs: $!condition.output-used, $!then.output-used,
            ($!else ?? $!else.output-used !! Empty)
    }

    method evaluate(Agrammon::Environment $env) {
        $!condition.evaluate($env)
            ?? $!then.evaluate($env)
            !! $!else ?? $!else.evaluate($env) !! Nil
    }
}

class Agrammon::Formula::Block does Agrammon::Formula {
    has Agrammon::Formula::StatementList $.statements;

    method input-used() { $!statements.input-used }
    method technical-used() { $!statements.technical-used }
    method output-used() { $!statements.output-used }

    method evaluate(Agrammon::Environment $env) {
        $env.enter-scope();
        LEAVE $env.leave-scope();
        $!statements.evaluate($env)
    }
}

class Agrammon::Formula::VarDecl does Agrammon::Formula::LValue {
    has Str $.name;

    method evaluate(Agrammon::Environment $env) is rw {
        $env.scope.declare($!name)
    }
}

class Agrammon::Formula::Var does Agrammon::Formula::LValue {
    has Str $.name;

    method evaluate(Agrammon::Environment $env) is rw {
        $env.scope.lookup($!name)
    }
}

class Agrammon::Formula::In does Agrammon::Formula {
    has $.symbol;

    method evaluate(Agrammon::Environment $env) {
        $env.input{$!symbol}
    }

    method input-used() { ($!symbol,) }
}

class Agrammon::Formula::Tech does Agrammon::Formula {
    has $.symbol;

    method evaluate(Agrammon::Environment $env) {
        $env.technical{$!symbol}
    }

    method technical-used() { ($!symbol,) }
}

class Agrammon::Formula::Val does Agrammon::Formula {
    has Agrammon::OutputReference $.reference;

    method evaluate(Agrammon::Environment $env) {
        $env.output{$!reference.module}{$!reference.symbol}
    }

    method output-used() { ($!reference,) }
}

class Agrammon::Formula::Integer does Agrammon::Formula {
    has Int $.value;
    method evaluate($) { $!value }
}

role Agrammon::Formula::BinOp does Agrammon::Formula {
    has Agrammon::Formula $.left;
    has Agrammon::Formula $.right;

    method input-used() {
        self!merge-inputs: $!left.input-used, $!right.input-used
    }

    method technical-used() {
        self!merge-technicals: $!left.technical-used, $!right.technical-used
    }

    method output-used() {
        self!merge-outputs: $!left.output-used, $!right.output-used
    }

    method prec() { ... }
    method assoc() { ... }
}

class Agrammon::Formula::BinOp::Multiply does Agrammon::Formula::BinOp {
    method prec() { 'u=' }
    method assoc() { 'left' }
    method evaluate(Agrammon::Environment $env) {
        $!left.evaluate($env) * $!right.evaluate($env)
    }
}

class Agrammon::Formula::BinOp::Add does Agrammon::Formula::BinOp {
    method prec() { 't=' }
    method assoc() { 'left' }
    method evaluate(Agrammon::Environment $env) {
        $!left.evaluate($env) + $!right.evaluate($env)
    }
}

role Agrammon::Formula::RelationalOp does Agrammon::Formula::BinOp {
    method prec() { 'm=' }
    method assoc() { 'left' }
}

class Agrammon::Formula::BinOp::NumericGreaterThan does Agrammon::Formula::RelationalOp {
    method evaluate(Agrammon::Environment $env) {
        $!left.evaluate($env) > $!right.evaluate($env)
    }
}

class Agrammon::Formula::BinOp::NumericGreaterThanOrEqual does Agrammon::Formula::RelationalOp {
    method evaluate(Agrammon::Environment $env) {
        $!left.evaluate($env) >= $!right.evaluate($env)
    }
}

class Agrammon::Formula::BinOp::NumericLessThan does Agrammon::Formula::RelationalOp {
    method evaluate(Agrammon::Environment $env) {
        $!left.evaluate($env) < $!right.evaluate($env)
    }
}

class Agrammon::Formula::BinOp::NumericLessThanOrEqual does Agrammon::Formula::RelationalOp {
    method evaluate(Agrammon::Environment $env) {
        $!left.evaluate($env) <= $!right.evaluate($env)
    }
}

class Agrammon::Formula::BinOp::NumericEqual does Agrammon::Formula::RelationalOp {
    method evaluate(Agrammon::Environment $env) {
        $!left.evaluate($env) == $!right.evaluate($env)
    }
}

class Agrammon::Formula::BinOp::NumericNotEqual does Agrammon::Formula::RelationalOp {
    method evaluate(Agrammon::Environment $env) {
        $!left.evaluate($env) != $!right.evaluate($env)
    }
}

class Agrammon::Formula::BinOp::Assign does Agrammon::Formula::BinOp {
    submethod TWEAK() {
        unless $!left ~~ Agrammon::Formula::LValue {
            die "Cannot assign to $!left.^name()";
        }
    }
    method prec() { 'i=' }
    method assoc() { 'right' }
    method evaluate(Agrammon::Environment $env) {
        $!left.evaluate($env) = $!right.evaluate($env)
    }
}
