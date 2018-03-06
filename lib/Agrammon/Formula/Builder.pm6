use Agrammon::Formula;
use Agrammon::OutputReference;

class Agrammon::Formula::Builder {
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
            Agrammon::Formula::When.new(
                test => $<EXPR>.ast,
                then => $statement
            )
        }
    }

    method statement_control:sym<if>($/) {
        make Agrammon::Formula::If.new(
            condition => $<EXPR>.ast,
            then => $<then>.ast,
            else => $<else> ?? $<else>.ast !! Nil
        );
    }

    method statement_control:sym<given>($/) {
        make Agrammon::Formula::Given.new(
            topic => $<EXPR>.ast,
            block => $<block>.ast
        );
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
        make Agrammon::Formula::Val.new(
            reference => Agrammon::OutputReference.new(
                symbol => ~$<symbol>,
                module => ~$<module>
            )
        );
    }

    method term:sym<Out>($/) {
        make Agrammon::Formula::Val.new(
            reference => Agrammon::OutputReference.new(
                symbol => ~$<symbol>,
                module => $*CURRENT-MODULE
            )
        );
    }

    method term:sym<Sum>($/) {
        make Agrammon::Formula::Sum.new(
            reference => Agrammon::OutputReference.new(
                symbol => ~$<symbol>,
                module => ~$<module>
            )
        );
    }

    method term:sym<my>($/) {
        make Agrammon::Formula::VarDecl.new(name => ~$<variable>);
    }

    method term:sym<variable>($/) {
        make Agrammon::Formula::Var.new(name => ~$<variable>);
    }

    method term:sym<return>($/) {
        make Agrammon::Formula::Return.new(
            expression => $<EXPR> ?? $<EXPR>.ast !! Agrammon::Formula::Nil.new
        );
    }

    method term:sym<( )>($/) {
        make $<EXPR>.ast;
    }

    method term:sym<integer>($/) {
        make Agrammon::Formula::Integer.new(value => +$/);
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

    method infix:sym</>($/) {
        make Agrammon::Formula::BinOp::Divide;
    }

    method infix:sym<*>($/) {
        make Agrammon::Formula::BinOp::Multiply;
    }

    method infix:sym<+>($/) {
        make Agrammon::Formula::BinOp::Add;
    }

    method infix:sym<->($/) {
        make Agrammon::Formula::BinOp::Subtract;
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

    method infix:sym<? :>($/) {
        make TernaryOperator.new(expression => $<EXPR>.ast);
    }
}
