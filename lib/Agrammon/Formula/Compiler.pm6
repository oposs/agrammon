use Agrammon::Formula;

unit module Agrammon::Fomula::Compiler;

sub compile-formula(Agrammon::Formula $formula --> Code) is export {
    use MONKEY-SEE-NO-EVAL;
    return EVAL compile($formula);
}

sub compile-formula-to-source(Agrammon::Formula $formula --> Str) is export {
    return compile($formula);
}

multi compile(Agrammon::Formula::Routine $r) {
    'sub ($env) { ' ~ compile($r.statements) ~ ' }';
}

multi compile(Agrammon::Formula::Block $b) {
    compile($b.statements)
}

multi compile(Agrammon::Formula::StatementList $s) {
    $s.statements.map(&compile).join("; ")
}

multi compile(Agrammon::Formula::If $if) {
    q:f"if &compile($if.condition) { &compile($if.then) }"
        ~ (q:f" else { &compile($if.else) }" if $if.else)
}

multi compile(Agrammon::Formula::Given $given) {
    q:f"given &compile($given.topic) { &compile($given.block) }"
}

multi compile(Agrammon::Formula::When $when) {
    q:f"when &compile($when.test) { &compile($when.block) }"
}

multi compile(Agrammon::Formula::Default $default) {
    q:f"default { &compile($default.block) }"
}

multi compile(Agrammon::Formula::WhenMod $when) {
    q:f"&compile($when.then) when &compile($when.test)"
}

multi compile(Agrammon::Formula::In $in) {
    q:c"$env.get-input('{$in.symbol}')"
}

multi compile(Agrammon::Formula::Tech $tech) {
    q:c"$env.get-technical('{$tech.symbol}')"
}

multi compile(Agrammon::Formula::TechIndirect $tech) {
    q:f"$env.get-technical(&compile($tech.expression))"
}

multi compile(Agrammon::Formula::Val $val) {
    given $val.reference {
        q:c"$env.output.get-output('{.module}', '{.symbol}')"
    }
}

multi compile(Agrammon::Formula::Sum $sum) {
    given $sum.reference {
        q:c"$env.output.get-sum('{.module}', '{.symbol}')"
    }
}

multi compile(Agrammon::Formula::Hash $hash) {
    q:c"%( {$hash.pairs.map(&compile).join(',')} )"
}

multi compile(Agrammon::Formula::Pair $pair) {
    q:c"{$pair.key.perl} => ({compile($pair.value)})"
}

multi compile(Agrammon::Formula::VarDecl $decl) {
    q:c"my {$decl.name}"
}

multi compile(Agrammon::Formula::Var $decl) {
    $decl.name
}

multi compile(Agrammon::Formula::CallBuiltin $call) {
    if $call.name eq 'return' {
        $call.args == 0 ?? 'return' !!
                $call.args == 1 ?? q:c"return {compile($call.args[0])}" !!
                        die "Can not do a multi-arg return";
    }
    else {
        q:c"$env.find-builtin({$call.name.perl})({$call.args.map(&compile).join(', ')})"
    }
}

multi compile(Agrammon::Formula::Not $op) {
    q:c"({compile($op.expression)}).not"
}

multi compile(Agrammon::Formula::Defined $op) {
    q:c"({compile($op.expression)}).defined"
}

multi compile(Agrammon::Formula::Lower $op) {
    q:c"({compile($op.expression)}).lc"
}

multi compile(Agrammon::Formula::Upper $op) {
    q:c"({compile($op.expression)}).uc"
}

multi compile(Agrammon::Formula::BinOp::Divide $op) {
    q:c"({compile($op.left)}) / ({compile($op.right)})"
}

multi compile(Agrammon::Formula::BinOp::DividePairwise $op) {
    q:c"$env.find-builtin('dividePairwise')(({compile($op.left)}), ({compile($op.right)}))"
}

multi compile(Agrammon::Formula::BinOp::Multiply $op) {
    q:c"({compile($op.left)}) * ({compile($op.right)})"
}

multi compile(Agrammon::Formula::BinOp::MultiplyPairwise $op) {
    q:c"$env.find-builtin('multiplyPairwise')(({compile($op.left)}), ({compile($op.right)}))"
}

multi compile(Agrammon::Formula::BinOp::Add $op) {
    q:c"({compile($op.left)}) + ({compile($op.right)})"
}

multi compile(Agrammon::Formula::BinOp::AddPairwise $op) {
    q:c"$env.find-builtin('addPairwise')(({compile($op.left)}), ({compile($op.right)}))"
}

multi compile(Agrammon::Formula::BinOp::Subtract $op) {
    q:c"({compile($op.left)}) - ({compile($op.right)})"
}

multi compile(Agrammon::Formula::BinOp::SubtractPairwise $op) {
    q:c"$env.find-builtin('subtractPairwise')(({compile($op.left)}), ({compile($op.right)}))"
}

multi compile(Agrammon::Formula::BinOp::Concatenate $op) {
    q:c"({compile($op.left)}) ~ ({compile($op.right)})"
}

multi compile(Agrammon::Formula::BinOp::NumericGreaterThan $op) {
    q:c"({compile($op.left)}) > ({compile($op.right)})"
}

multi compile(Agrammon::Formula::BinOp::NumericGreaterThanOrEqual $op) {
    q:c"({compile($op.left)}) >= ({compile($op.right)})"
}

multi compile(Agrammon::Formula::BinOp::NumericLessThan $op) {
    q:c"({compile($op.left)}) < ({compile($op.right)})"
}

multi compile(Agrammon::Formula::BinOp::NumericLessThanOrEqual $op) {
    q:c"({compile($op.left)}) <= ({compile($op.right)})"
}

multi compile(Agrammon::Formula::BinOp::NumericEqual $op) {
    q:c"({compile($op.left)}) == ({compile($op.right)})"
}

multi compile(Agrammon::Formula::BinOp::NumericNotEqual $op) {
    q:c"({compile($op.left)}) != ({compile($op.right)})"
}

multi compile(Agrammon::Formula::BinOp::StringEqual $op) {
    q:c"({compile($op.left)}) eq ({compile($op.right)})"
}

multi compile(Agrammon::Formula::BinOp::StringNotEqual $op) {
    q:c"({compile($op.left)}) ne ({compile($op.right)})"
}

multi compile(Agrammon::Formula::BinOp::TightAnd $op) {
    q:c"({compile($op.left)}) && ({compile($op.right)})"
}

multi compile(Agrammon::Formula::BinOp::TightOr $op) {
    q:c"({compile($op.left)}) || ({compile($op.right)})"
}

multi compile(Agrammon::Formula::BinOp::DefinedOr $op) {
    q:c"({compile($op.left)}) // ({compile($op.right)})"
}

multi compile(Agrammon::Formula::BinOp::LooseAnd $op) {
    q:c"({compile($op.left)}) && ({compile($op.right)})"
}

multi compile(Agrammon::Formula::BinOp::LooseOr $op) {
    q:c"({compile($op.left)}) || ({compile($op.right)})"
}

multi compile(Agrammon::Formula::BinOp::Assign $op) {
    q:c"({compile($op.left)}) = ({compile($op.right)})"
}

multi compile(Agrammon::Formula::Integer $val) {
    $val.value.perl
}

multi compile(Agrammon::Formula::Rational $val) {
    $val.value.perl
}

multi compile(Agrammon::Formula::Float $val) {
    $val.value.perl
}

multi compile(Agrammon::Formula::String $val) {
    $val.value.perl
}

multi compile(Agrammon::Formula::Nil) {
    'Nil'
}
