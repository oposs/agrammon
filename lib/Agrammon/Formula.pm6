use Agrammon::Environment;
use Agrammon::Formula::ControlFlow;
use Agrammon::OutputReference;

role Agrammon::Formula {
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
}

class Agrammon::Formula::Block does Agrammon::Formula {
    has Agrammon::Formula::StatementList $.statements;

    method input-used() { $!statements.input-used }
    method technical-used() { $!statements.technical-used }
    method output-used() { $!statements.output-used }
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
}

class Agrammon::Formula::When does Agrammon::Formula {
    has Agrammon::Formula $.test;
    has Agrammon::Formula::Block $.block;

    method input-used() {
        self!merge-inputs: $!test.input-used, $!block.input-used
    }

    method technical-used() {
        self!merge-technicals: $!test.technical-used, $!block.technical-used
    }

    method output-used() {
        self!merge-outputs: $!test.output-used, $!block.output-used
    }
}

class Agrammon::Formula::Default does Agrammon::Formula {
    has Agrammon::Formula $.block;

    method input-used() {
        self!merge-inputs: $!block.input-used
    }

    method technical-used() {
        self!merge-technicals: $!block.technical-used
    }

    method output-used() {
        self!merge-outputs: $!block.output-used
    }
}

class Agrammon::Formula::WhenMod does Agrammon::Formula {
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
}

class Agrammon::Formula::VarDecl does Agrammon::Formula::LValue {
    has Str $.name;
}

class Agrammon::Formula::Var does Agrammon::Formula::LValue {
    has Str $.name;
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
}

role Agrammon::Formula::OneExpressionBuiltin does Agrammon::Formula {
    has Agrammon::Formula $.expression;

    method input-used() { $!expression.input-used }
    method technical-used() { $!expression.technical-used }
    method output-used() { $!expression.output-used }
}

class Agrammon::Formula::Not does Agrammon::Formula::OneExpressionBuiltin {
}

class Agrammon::Formula::Defined does Agrammon::Formula::OneExpressionBuiltin {
}

class Agrammon::Formula::Lower does Agrammon::Formula::OneExpressionBuiltin {
}

class Agrammon::Formula::Upper does Agrammon::Formula::OneExpressionBuiltin {
}

class Agrammon::Formula::In does Agrammon::Formula {
    has $.symbol;

    method input-used() { ($!symbol,) }
}

class Agrammon::Formula::Tech does Agrammon::Formula {
    has $.symbol;

    method technical-used() { ($!symbol,) }
}

class Agrammon::Formula::TechIndirect does Agrammon::Formula::OneExpressionBuiltin {
}

class Agrammon::Formula::Val does Agrammon::Formula {
    has Agrammon::OutputReference $.reference;

    method output-used() { ($!reference,) }
}

class Agrammon::Formula::Sum does Agrammon::Formula {
    has Agrammon::OutputReference $.reference;

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
}

class Agrammon::Formula::Pair does Agrammon::Formula {
    has Str $.key;
    has Agrammon::Formula $.value;

    method input-used() { $!value.input-used }
    method technical-used() { $!value.technical-used }
    method output-used() { $!value.output-used }
}

class Agrammon::Formula::Integer does Agrammon::Formula {
    has Int $.value;
}

class Agrammon::Formula::Rational does Agrammon::Formula {
    has Rat $.value;
}

class Agrammon::Formula::Float does Agrammon::Formula {
    has Num $.value;
}

class Agrammon::Formula::String does Agrammon::Formula {
    has Str $.value;
}

class Agrammon::Formula::Nil does Agrammon::Formula {
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
}

class Agrammon::Formula::BinOp::DividePairwise does Agrammon::Formula::BinOp {
    method prec() { 'u=' }
    method assoc() { 'left' }
}

class Agrammon::Formula::BinOp::Multiply does Agrammon::Formula::BinOp {
    method prec() { 'u=' }
    method assoc() { 'left' }
}

class Agrammon::Formula::BinOp::MultiplyPairwise does Agrammon::Formula::BinOp {
    method prec() { 'u=' }
    method assoc() { 'left' }
}

class Agrammon::Formula::BinOp::Add does Agrammon::Formula::BinOp {
    method prec() { 't=' }
    method assoc() { 'left' }
}

class Agrammon::Formula::BinOp::AddPairwise does Agrammon::Formula::BinOp {
    method prec() { 't=' }
    method assoc() { 'left' }
}

class Agrammon::Formula::BinOp::Subtract does Agrammon::Formula::BinOp {
    method prec() { 't=' }
    method assoc() { 'left' }
}

class Agrammon::Formula::BinOp::SubtractPairwise does Agrammon::Formula::BinOp {
    method prec() { 't=' }
    method assoc() { 'left' }
}

class Agrammon::Formula::BinOp::Concatenate does Agrammon::Formula::BinOp {
    method prec() { 'r=' }
    method assoc() { 'left' }
}

role Agrammon::Formula::RelationalOp does Agrammon::Formula::BinOp {
    method prec() { 'm=' }
    method assoc() { 'left' }
}

class Agrammon::Formula::BinOp::NumericGreaterThan does Agrammon::Formula::RelationalOp {
}

class Agrammon::Formula::BinOp::NumericGreaterThanOrEqual does Agrammon::Formula::RelationalOp {
}

class Agrammon::Formula::BinOp::NumericLessThan does Agrammon::Formula::RelationalOp {
}

class Agrammon::Formula::BinOp::NumericLessThanOrEqual does Agrammon::Formula::RelationalOp {
}

class Agrammon::Formula::BinOp::NumericEqual does Agrammon::Formula::RelationalOp {
}

class Agrammon::Formula::BinOp::NumericNotEqual does Agrammon::Formula::RelationalOp {
}

class Agrammon::Formula::BinOp::StringEqual does Agrammon::Formula::RelationalOp {
}

class Agrammon::Formula::BinOp::StringNotEqual does Agrammon::Formula::RelationalOp {
}

class Agrammon::Formula::BinOp::TightAnd does Agrammon::Formula::BinOp {
    method prec() { 'l=' }
    method assoc() { 'left' }
}

class Agrammon::Formula::BinOp::TightOr does Agrammon::Formula::BinOp {
    method prec() { 'k=' }
    method assoc() { 'left' }
}

class Agrammon::Formula::BinOp::DefinedOr does Agrammon::Formula::BinOp {
    method prec() { 'k=' }
    method assoc() { 'left' }
}

class Agrammon::Formula::BinOp::LooseAnd does Agrammon::Formula::BinOp {
    method prec() { 'd=' }
    method assoc() { 'left' }
}

class Agrammon::Formula::BinOp::LooseOr does Agrammon::Formula::BinOp {
    method prec() { 'c=' }
    method assoc() { 'left' }
}

class Agrammon::Formula::BinOp::Assign does Agrammon::Formula::BinOp {
    submethod TWEAK() {
        unless $!left ~~ Agrammon::Formula::LValue {
            die "Cannot assign to $!left.^name()";
        }
    }
    method prec() { 'i=' }
    method assoc() { 'right' }
}
