use Agrammon::Preprocessor;
use Test;

is preprocess(Q:to/IN/, {}), Q:to/OUT/, 'Something without directives is translated directly';
    line 1
    line 2
    line 3
    IN
    line 1
    line 2
    line 3
    OUT

is preprocess(Q:to/IN/, {}), Q:to/OUT/, '?if on non-present option is omitted';
    line 1
    ?if A
    line 2
    ?endif
    line 3
    IN
    line 1



    line 3
    OUT

is preprocess(Q:to/IN/, {}), Q:to/OUT/, '?ifnot on non-present option is included';
    line 1
    ?ifnot A
    line 2
    ?endif
    line 3
    IN
    line 1

    line 2

    line 3
    OUT

is preprocess(Q:to/IN/, {:!A}), Q:to/OUT/, '?if on present but false option is omitted';
    line 1
    ?if A
    line 2
    ?endif
    line 3
    IN
    line 1



    line 3
    OUT

is preprocess(Q:to/IN/, {:A}), Q:to/OUT/, '?ifnot on present but false option is omitted';
    line 1
    ?ifnot A
    line 2
    ?endif
    line 3
    IN
    line 1



    line 3
    OUT

is preprocess(Q:to/IN/, {:A}), Q:to/OUT/, '?if on present and true option included';
    line 1
    ?if A
    line 2
    ?endif
    line 3
    IN
    line 1

    line 2

    line 3
    OUT

is preprocess(Q:to/IN/, {:!A}), Q:to/OUT/, '?ifnot on present and true option included';
    line 1
    ?ifnot A
    line 2
    ?endif
    line 3
    IN
    line 1

    line 2

    line 3
    OUT

is preprocess(Q:to/IN/, {:A, :B}), Q:to/OUT/, 'Nested ?if works (both true)';
    line 1
    ?if A
    line 2
    ?if B
    line 3
    ?endif
    ?endif
    line 4
    IN
    line 1

    line 2

    line 3


    line 4
    OUT

is preprocess(Q:to/IN/, {:!A, :!B}), Q:to/OUT/, 'Nested ?ifnot works (both true)';
    line 1
    ?ifnot A
    line 2
    ?ifnot B
    line 3
    ?endif
    ?endif
    line 4
    IN
    line 1

    line 2

    line 3


    line 4
    OUT

is preprocess(Q:to/IN/, {:A, :!B}), Q:to/OUT/, 'Nested ?if works (outer true)';
    line 1
    ?if A
    line 2
    ?if B
    line 3
    ?endif
    ?endif
    line 4
    IN
    line 1

    line 2




    line 4
    OUT
    
is preprocess(Q:to/IN/, {:!A, :B}), Q:to/OUT/, 'Nested ?ifnot works (outer true)';
    line 1
    ?ifnot A
    line 2
    ?ifnot B
    line 3
    ?endif
    ?endif
    line 4
    IN
    line 1

    line 2




    line 4
    OUT

is preprocess(Q:to/IN/, {:!A, :B}), Q:to/OUT/, 'Nested ?if works (inner true)';
    line 1
    ?if A
    line 2
    ?if B
    line 3
    ?endif
    ?endif
    line 4
    IN
    line 1






    line 4
    OUT

is preprocess(Q:to/IN/, {:A, :!B}), Q:to/OUT/, 'Nested ?ifnot works (inner true)';
    line 1
    ?ifnot A
    line 2
    ?ifnot B
    line 3
    ?endif
    ?endif
    line 4
    IN
    line 1






    line 4
    OUT

is preprocess(Q:to/IN/, {:!A}), Q:to/OUT/, 'Emit ?else part when condition is false';
    line 1
    ?if A
    line 2
    ?else
    line 3
    ?endif
    line 4
    IN
    line 1



    line 3

    line 4
    OUT

is preprocess(Q:to/IN/, {:A}), Q:to/OUT/, 'Do not emit ?else part when condition is true';
    line 1
    ?if A
    line 2
    ?else
    line 3
    ?endif
    line 4
    IN
    line 1

    line 2



    line 4
    OUT

is preprocess(Q:to/IN/, {:!A, :!B}), Q:to/OUT/, 'if/elsif/else emits else if no conditions true';
    line 1
    ?if A
    line 2
    ?elsif B
    line 3
    ?else
    line 4
    ?endif
    line 5
    IN
    line 1





    line 4

    line 5
    OUT

is preprocess(Q:to/IN/, {:A, :B}), Q:to/OUT/, 'if/elsif/else emits first true part (when if)';
    line 1
    ?if A
    line 2
    ?elsif B
    line 3
    ?else
    line 4
    ?endif
    line 5
    IN
    line 1

    line 2





    line 5
    OUT

is preprocess(Q:to/IN/, {:!A, :B}), Q:to/OUT/, 'if/elsif/else emits first true part (when elsif)';
    line 1
    ?if A
    line 2
    ?elsif B
    line 3
    ?else
    line 4
    ?endif
    line 5
    IN
    line 1



    line 3



    line 5
    OUT


throws-like { preprocess(Q:to/IN/, {}) }, X::Agrammon::Preprocessor::InvalidDirective, line => 2;
    line 1
    ?monkey
    line 2
    IN

throws-like { preprocess(Q:to/IN/, {}) }, X::Agrammon::Preprocessor::UnclosedDirective, line => 2;
    line 1
    ?if opt
    line 2
    IN

throws-like { preprocess(Q:to/IN/, {}) }, X::Agrammon::Preprocessor::UnclosedDirective, line => 2;
    line 1
    ?ifnot opt
    line 2
    IN

throws-like { preprocess(Q:to/IN/, {}) }, X::Agrammon::Preprocessor::UnexpectedCloser, line => 2, unexpected => '?endif';
    line 1
    ?endif
    line 2
    IN

throws-like { preprocess(Q:to/IN/, {}) }, X::Agrammon::Preprocessor::UnexpectedCloser, line => 2, unexpected => '?else';
    line 1
    ?else
    line 2
    IN

throws-like { preprocess(Q:to/IN/, {}) }, X::Agrammon::Preprocessor::UnexpectedCloser, line => 2, unexpected => '?elsif';
    line 1
    ?elsif A
    line 2
    IN

throws-like { preprocess(Q:to/IN/, {}) }, X::Agrammon::Preprocessor::ElsifAfterElse, line => 5;
    ?if A
    line 1
    ?else
    line 2
    ?elsif B
    line 3
    ?endif
    IN

throws-like { preprocess(Q:to/IN/, {}) }, X::Agrammon::Preprocessor::ElsifAfterElse, line => 5;
    ?ifnot A
    line 1
    ?else
    line 2
    ?elsif B
    line 3
    ?endif
    IN

done-testing;
