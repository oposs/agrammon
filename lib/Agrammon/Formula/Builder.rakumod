use v6;
use Agrammon::Formula;
use Agrammon::OutputReference;

class Agrammon::Formula::Builder {
    has Bool $.on-input;

    method TOP($/) {
        make Agrammon::Formula::Routine.new(
            statements => $<statementlist>.ast
        );
    }

    method statementlist($/) {
        make Agrammon::Formula::StatementList.new(
            statements => $<statement>.map(*.ast)
        );
    }

    method statement($/) {
        with $<statement_control> {
            make .ast;
        }
        else {
            my $ast = $<EXPR>.ast;
            with $<statement_modifier> {
                $ast = .ast()($ast);
            }
            make $ast;
        }
    }

    method statement_modifier:sym<when>($/) {
        make -> $statement {
            Agrammon::Formula::WhenMod.new(
                test => $<EXPR>.ast,
                then => $statement
            )
        }
    }

    method statement_modifier:sym<if>($/) {
        make -> $statement {
            Agrammon::Formula::If.new(
                condition => $<EXPR>.ast,
                then => $statement,
                else => Nil
            )
        }
    }

    method statement_modifier:sym<unless>($/) {
        make -> $statement {
            Agrammon::Formula::If.new(
                condition => $<EXPR>.ast,
                then => Agrammon::Formula::Nil.new,
                else => $statement
            )
        }
    }

    method statement_control:sym<if>($/) {
        my $else := $<else> ?? $<else>.ast !! Nil;
        my @elsif-cond = $<elsif-cond>.map(*.ast);
        my @elsif = $<elsif>.map(*.ast);
        while @elsif {
            $else := Agrammon::Formula::If.new(
                condition => @elsif-cond.pop,
                then => @elsif.pop,
                else => $else
            );
        }
        make Agrammon::Formula::If.new(
            condition => $<if-cond>.ast,
            then => $<then>.ast,
            else => $else
        );
    }

    method statement_control:sym<given>($/) {
        make Agrammon::Formula::Given.new(
            topic => $<EXPR>.ast,
            block => $<block>.ast
        );
    }

    method statement_control:sym<when>($/) {
        make Agrammon::Formula::When.new(
            test => $<EXPR>.ast,
            block => $<block>.ast
        )
    }

    method statement_control:sym<default>($/) {
        make Agrammon::Formula::Default.new(
            block => $<block>.ast
        )
    }


    method block($/) {
        make Agrammon::Formula::Block.new(
            statements => $<statementlist>.ast
        );
    }

    my class TernaryOperator {
        has $.expression;
        method prec() { 'j=' }
        method assoc() { 'right' }
    }

    method EXPR($/) {
        my @terms-parsed = $<term>.map(*.ast);
        my @ops-parsed = $<infix>.map(*.ast);
        my @termstack = @terms-parsed.shift;

        my @opstack;
        my $opprec = '';
        while @ops-parsed {
            my $op = @ops-parsed.shift;
            my $inprec = $op.prec;
            while @opstack {
                $opprec = @opstack[*-1].prec;
                last unless $opprec gt $inprec;
                reduce(@termstack, @opstack);
            }

            if $opprec eq $inprec {
                if $op.assoc eq 'left' {
                    reduce(@termstack, @opstack);
                }
            }

            @opstack.push($op);
            @termstack.push(@terms-parsed.shift);
        }

        reduce(@termstack, @opstack) while @opstack;
        make @termstack[0];
    }

    sub reduce(@termstack, @opstack) {
        my $right = @termstack.pop;
        my $left = @termstack.pop;
        given @opstack.pop {
            when TernaryOperator {
                @termstack.push(Agrammon::Formula::If.new(
                    condition => $left,
                    then => .expression,
                    else => $right
                ));
            }
            default {
                @termstack.push(.new(:$left, :$right));
            }
        }
    }

    method term:sym<In>($/) {
        make Agrammon::Formula::In.new(symbol => ~$<symbol>);
    }

    method term:sym<Tech>($/) {
        make Agrammon::Formula::Tech.new(symbol => ~$<symbol>);
    }

    method term:sym<Val>($/) {
        self!no-input('Val');
        make Agrammon::Formula::Val.new(
            reference => Agrammon::OutputReference.new(
                symbol => ~$<symbol>,
                module => $<module>.ast
            )
        );
    }

    method term:sym<Out>($/) {
        self!no-input('Out');
        make Agrammon::Formula::Val.new(
            reference => Agrammon::OutputReference.new(
                symbol => ~$<symbol>,
                module => $*CURRENT-MODULE
            )
        );
    }

    method term:sym<Sum>($/) {
        self!no-input('Sum');
        make Agrammon::Formula::Sum.new(
            reference => Agrammon::OutputReference.new(
                symbol => ~$<symbol>,
                module => $<module>.ast
            )
        );
    }

    method !no-input(Str $what) {
        if $!on-input {
            $/.panic("Cannot use $what on an input formula");
        }
    }

    method term:sym<$TE>($/) {
        make Agrammon::Formula::TechIndirect.new(expression => $<EXPR>.ast);
    }

    method term:sym<call>($/) {
        make Agrammon::Formula::CallBuiltin.new(
            name => ~$<ident>,
            args => $<arg>.map(*.ast)
        );
    }

    method term:sym<return>($/) {
        make Agrammon::Formula::CallBuiltin.new(
            name => 'return',
            args => $<EXPR> ?? ($<EXPR>.ast) !! ()
        );
    }

    method term:sym<listop>($/) {
        make Agrammon::Formula::CallBuiltin.new(
            name => ~$<ident>,
            args => $<arg>.map(*.ast)
        );
    }

    method term:sym<my>($/) {
        make Agrammon::Formula::VarDecl.new(name => ~$<variable>);
    }

    method term:sym<variable>($/) {
        make Agrammon::Formula::Var.new(name => ~$<variable>);
    }

    method term:sym<not>($/) {
        make Agrammon::Formula::Not.new(
            expression => $<EXPR>.ast
        );
    }

    method term:sym<defined>($/) {
        make Agrammon::Formula::Defined.new(
            expression => $<term>.ast
        );
    }

    method term:sym<lc>($/) {
        make Agrammon::Formula::Lower.new(
            expression => $<term>.ast
        );
    }

    method term:sym<uc>($/) {
        make Agrammon::Formula::Upper.new(
            expression => $<term>.ast
        );
    }

    method term:sym<( )>($/) {
        make $<EXPR>.ast;
    }

    method term:sym<{ }>($/) {
        make Agrammon::Formula::Hash.new(
            pairs => $<pair>.map(*.ast)
        );
    }

    method pair($/) {
        make Agrammon::Formula::Pair.new(
            key => ~$<ident>,
            value => $<EXPR>.ast
        );
    }

    method term:sym<integer>($/) {
        make Agrammon::Formula::Integer.new(value => +$/);
    }

    method term:sym<rational>($/) {
        make Agrammon::Formula::Rational.new(value => +$/);
    }

    method term:sym<float>($/) {
        make Agrammon::Formula::Float.new(value => +$/);
    }

    method term:sym<single-string>($/) {
        make Agrammon::Formula::String.new(
            value => $<single-string-piece>.map(*.ast).join
        );
    }

    method single-string-piece:sym<non-esc>($/) {
        make ~$/;
    }

    method single-string-piece:sym<esc>($/) {
        make ~$<escaped>;
    }

    method term:sym<double-string>($/) {
        make Agrammon::Formula::String.new(
            value => $<double-string-piece>.map(*.ast).join
        );
    }

    method double-string-piece:sym<non-esc>($/) {
        make ~$/;
    }

    method double-string-piece:sym<esc>($/) {
        my constant SEQS = { n => "\n", r => "\r", t => "\t", 0 => "\0" };
        make $<escaped>
            ?? ~$<escaped>
            !! SEQS{~$<sequence>};
    }

    method infix:sym</>($/) {
        make Agrammon::Formula::BinOp::Divide;
    }

    method infix:sym<P/>($/) {
        make Agrammon::Formula::BinOp::DividePairwise;
    }

    method infix:sym<*>($/) {
        make Agrammon::Formula::BinOp::Multiply;
    }

    method infix:sym<P*>($/) {
        make Agrammon::Formula::BinOp::MultiplyPairwise;
    }

    method infix:sym<+>($/) {
        make Agrammon::Formula::BinOp::Add;
    }

    method infix:sym<P+>($/) {
        make Agrammon::Formula::BinOp::AddPairwise;
    }

    method infix:sym<->($/) {
        make Agrammon::Formula::BinOp::Subtract;
    }

    method infix:sym<P->($/) {
        make Agrammon::Formula::BinOp::SubtractPairwise;
    }

    method infix:sym<.>($/) {
        make Agrammon::Formula::BinOp::Concatenate;
    }

    method infix:sym<=>($/) {
        make Agrammon::Formula::BinOp::Assign;
    }

    method infix:sym<< > >>($/) {
        make Agrammon::Formula::BinOp::NumericGreaterThan;
    }

    method infix:sym<< >= >>($/) {
        make Agrammon::Formula::BinOp::NumericGreaterThanOrEqual;
    }

    method infix:sym<< < >>($/) {
        make Agrammon::Formula::BinOp::NumericLessThan;
    }

    method infix:sym<< <= >>($/) {
        make Agrammon::Formula::BinOp::NumericLessThanOrEqual;
    }

    method infix:sym<< == >>($/) {
        make Agrammon::Formula::BinOp::NumericEqual;
    }

    method infix:sym<< != >>($/) {
        make Agrammon::Formula::BinOp::NumericNotEqual;
    }

    method infix:sym<eq>($/) {
        make Agrammon::Formula::BinOp::StringEqual;
    }

    method infix:sym<ne>($/) {
        make Agrammon::Formula::BinOp::StringNotEqual;
    }

    method infix:sym<and>($/) {
        make Agrammon::Formula::BinOp::LooseAnd;
    }

    method infix:sym<or>($/) {
        make Agrammon::Formula::BinOp::LooseOr;
    }

    method infix:sym<&&>($/) {
        make Agrammon::Formula::BinOp::TightAnd;
    }

    method infix:sym<||>($/) {
        make Agrammon::Formula::BinOp::TightOr;
    }

    method infix:sym<//>($/) {
        make Agrammon::Formula::BinOp::DefinedOr;
    }

    method infix:sym<? :>($/) {
        make TernaryOperator.new(expression => $<EXPR>.ast);
    }

    method name($/) {
        my @parts = $<name-part>.map(~*);
        my @current;
        unless $<root> {
            @current = $*CURRENT-MODULE.split('::').head(*-1);
            while @parts && @parts[0] eq '..' {
                @parts.shift;
                @current.pop;
            }
        }
        unless @parts {
            die "Name $/ must have at least one named part";
        }
        if any(@parts) eq '..' {
            die "Name $/ is invalid due to non-leading use of `..`";
        }
        make (flat @current, @parts).join('::');
    }
}
