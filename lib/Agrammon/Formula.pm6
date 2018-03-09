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

class X::Agrammon::Formula::ReturnException is Exception {
    has $.payload is default(Nil);
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

class Agrammon::Formula::Routine does Agrammon::Formula {
    has Agrammon::Formula::StatementList $.statements;

    method input-used() { $!statements.input-used }
    method technical-used() { $!statements.technical-used }
    method output-used() { $!statements.output-used }

    method evaluate(Agrammon::Environment $env) {
        return $!statements.evaluate($env);
        CATCH {
            when X::Agrammon::Formula::ReturnException {
                return .payload;
            }
        }
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
        if %_<topic>:exists {
            $env.scope.declare('$_');
            $env.scope.lookup('$_') = %_<topic>;
        }
        $!statements.evaluate($env)
    }
}

class Agrammon::Formula::Given does Agrammon::Formula {
    has Agrammon::Formula $.topic;
    has Agrammon::Formula::Block $.block;

    method input-used() {
        self!merge-inputs: $!topic.input-used, $!block.input-used
    }

    method technical-used() {
        self!merge-technicals: $!topic.technical-used, $!block.technical-used
    }

    method output-used() {
        self!merge-outputs: $!topic.output-used, $!block.output-used
    }

    method evaluate(Agrammon::Environment $env) {
        $!block.evaluate($env, topic => $!topic.evaluate($env))
    }
}

class Agrammon::Formula::When does Agrammon::Formula {
    has Agrammon::Formula $.test;
    has Agrammon::Formula $.then;

    method input-used() {
        self!merge-inputs: $!test.input-used, $!then.input-used
    }

    method technical-used() {
        self!merge-technicals: $!test.technical-used, $!then.technical-used
    }

    method output-used() {
        self!merge-outputs: $!test.output-used, $!then.output-used
    }

    method evaluate(Agrammon::Environment $env) {
        if $!test.evaluate($env) ~~ $env.scope.lookup('$_') {
            $!then.evaluate($env);
        }
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

class Agrammon::Formula::CallBuiltin does Agrammon::Formula::LValue {
    has Str $.name;
    has Agrammon::Formula @.args;

    method input-used() {
        self!merge-inputs: @!args.map(*.input-used)
    }

    method technical-used() {
        self!merge-technicals: @!args.map(*.technical-used)
    }

    method output-used() {
        self!merge-outputs: @!args.map(*.output-used)
    }

    method evaluate(Agrammon::Environment $env) is rw {
        with $env.builtins{$!name} {
            .(|@!args.map(*.evaluate($env)))
        }
        else {
            die "No such builtin function '$!name'";
        }
    }
}

role Agrammon::Formula::OneExpressionBuiltin does Agrammon::Formula {
    has Agrammon::Formula $.expression;

    method input-used() { $!expression.input-used }
    method technical-used() { $!expression.technical-used }
    method output-used() { $!expression.output-used }
}

class Agrammon::Formula::Return does Agrammon::Formula::OneExpressionBuiltin {
    method evaluate(Agrammon::Environment $env) {
        die X::Agrammon::Formula::ReturnException.new(
            payload => $!expression.evaluate($env)
        );
    }
}

class X::Agrammon::Formula::Died is Exception {
    has $.message;
}

class Agrammon::Formula::Die does Agrammon::Formula::OneExpressionBuiltin {
    method evaluate(Agrammon::Environment $env) {
        die X::Agrammon::Formula::Died.new(message => $!expression.evaluate($env));
    }
}

class Agrammon::Formula::Warn does Agrammon::Formula::OneExpressionBuiltin {
    method evaluate(Agrammon::Environment $env) {
        warn $!expression.evaluate($env);
    }
}

class Agrammon::Formula::Defined does Agrammon::Formula::OneExpressionBuiltin {
    method evaluate(Agrammon::Environment $env) {
        defined $!expression.evaluate($env)
    }
}

class Agrammon::Formula::Lower does Agrammon::Formula::OneExpressionBuiltin {
    method evaluate(Agrammon::Environment $env) {
        $!expression.evaluate($env).lc
    }
}

class Agrammon::Formula::Upper does Agrammon::Formula::OneExpressionBuiltin {
    method evaluate(Agrammon::Environment $env) {
        $!expression.evaluate($env).uc
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

class Agrammon::Formula::TechIndirect does Agrammon::Formula::OneExpressionBuiltin {
    method evaluate(Agrammon::Environment $env) {
        $env.technical{$!expression.evaluate($env)}
    }
}

class Agrammon::Formula::Val does Agrammon::Formula {
    has Agrammon::OutputReference $.reference;

    method evaluate(Agrammon::Environment $env) {
        $env.output{$!reference.module}{$!reference.symbol}
    }

    method output-used() { ($!reference,) }
}

class Agrammon::Formula::Sum does Agrammon::Formula {
    has Agrammon::OutputReference $.reference;

    method evaluate(Agrammon::Environment $env) {
        given $env.output{$!reference.module}{$!reference.symbol} {
            when Iterable {
                .sum
            }
            default {
                die "Expected multiple results for $!reference.module()::$!reference.symbol()";
            }
        }
    }

    method output-used() { ($!reference,) }
}

class Agrammon::Formula::Hash does Agrammon::Formula {
    has Agrammon::Formula @.pairs;

    method input-used() {
        self!merge-inputs: @!pairs.map(*.input-used)
    }

    method technical-used() {
        self!merge-technicals: @!pairs.map(*.technical-used)
    }

    method output-used() {
        self!merge-outputs: @!pairs.map(*.output-used)
    }

    method evaluate(Agrammon::Environment $env) is rw {
        %( @!pairs.map(*.evaluate($env)) )
    }
}

class Agrammon::Formula::Pair does Agrammon::Formula {
    has Str $.key;
    has Agrammon::Formula $.value;

    method input-used() { $!value.input-used }
    method technical-used() { $!value.technical-used }
    method output-used() { $!value.output-used }

    method evaluate(Agrammon::Environment $env) {
        $!key => $!value.evaluate($env)
    }
}

class Agrammon::Formula::Integer does Agrammon::Formula {
    has Int $.value;
    method evaluate($) { $!value }
}

class Agrammon::Formula::Rational does Agrammon::Formula {
    has Rat $.value;
    method evaluate($) { $!value }
}

class Agrammon::Formula::String does Agrammon::Formula {
    has Str $.value;
    method evaluate($) { $!value }
}

class Agrammon::Formula::Nil does Agrammon::Formula {
    method evaluate($) { Nil }
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

class Agrammon::Formula::BinOp::Divide does Agrammon::Formula::BinOp {
    method prec() { 'u=' }
    method assoc() { 'left' }
    method evaluate(Agrammon::Environment $env) {
        $!left.evaluate($env) / $!right.evaluate($env)
    }
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

class Agrammon::Formula::BinOp::Subtract does Agrammon::Formula::BinOp {
    method prec() { 't=' }
    method assoc() { 'left' }
    method evaluate(Agrammon::Environment $env) {
        $!left.evaluate($env) - $!right.evaluate($env)
    }
}

class Agrammon::Formula::BinOp::Concatenate does Agrammon::Formula::BinOp {
    method prec() { 'r=' }
    method assoc() { 'left' }
    method evaluate(Agrammon::Environment $env) {
        $!left.evaluate($env) ~ $!right.evaluate($env)
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

class Agrammon::Formula::BinOp::StringEqual does Agrammon::Formula::RelationalOp {
    method evaluate(Agrammon::Environment $env) {
        $!left.evaluate($env) eq $!right.evaluate($env)
    }
}

class Agrammon::Formula::BinOp::StringNotEqual does Agrammon::Formula::RelationalOp {
    method evaluate(Agrammon::Environment $env) {
        $!left.evaluate($env) ne $!right.evaluate($env)
    }
}

class Agrammon::Formula::BinOp::TightAnd does Agrammon::Formula::BinOp {
    method prec() { 'l=' }
    method assoc() { 'left' }
    method evaluate(Agrammon::Environment $env) {
        $!left.evaluate($env) && $!right.evaluate($env)
    }
}

class Agrammon::Formula::BinOp::TightOr does Agrammon::Formula::BinOp {
    method prec() { 'k=' }
    method assoc() { 'left' }
    method evaluate(Agrammon::Environment $env) {
        $!left.evaluate($env) || $!right.evaluate($env)
    }
}

class Agrammon::Formula::BinOp::DefinedOr does Agrammon::Formula::BinOp {
    method prec() { 'k=' }
    method assoc() { 'left' }
    method evaluate(Agrammon::Environment $env) {
        $!left.evaluate($env) // $!right.evaluate($env)
    }
}

class Agrammon::Formula::BinOp::LooseAnd does Agrammon::Formula::BinOp {
    method prec() { 'd=' }
    method assoc() { 'left' }
    method evaluate(Agrammon::Environment $env) {
        $!left.evaluate($env) && $!right.evaluate($env)
    }
}

class Agrammon::Formula::BinOp::LooseOr does Agrammon::Formula::BinOp {
    method prec() { 'c=' }
    method assoc() { 'left' }
    method evaluate(Agrammon::Environment $env) {
        $!left.evaluate($env) || $!right.evaluate($env)
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
