use Agrammon::Formula;
use Agrammon::OutputReference;

class Agrammon::Formula::Builder {
    method TOP($/) {
        make $<statementlist>.ast;
    }

    method statementlist($/) {
        make Agrammon::Formula::StatementList.new(
            statements => $<EXPR>.map(*.ast)
        );
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
        my $op-type = @opstack.pop;
        @termstack.push($op-type.new(:$left, :$right));
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

    method infix:sym<*>($/) {
        make Agrammon::Formula::BinOp::Multiply;
    }

    method infix:sym<+>($/) {
        make Agrammon::Formula::BinOp::Add;
    }
}
