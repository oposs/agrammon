use v6;

use Agrammon::LanguageParser;

class Agrammon::Model::Result {
    has Str $.name;
    has Str $.type;
    has %.selector{Str};
    has @!data-order;
    has %!data-lookup;
    has Str $.order;
    has Bool $!submit = False;
    has Bool $!result-view = False;

    submethod TWEAK( :$results, :$submit, :@data --> Nil) {
        with $results {
            if .lc eq 'true' {
                $!result-view = True;
            }
        }
        with $submit {
            if .lc eq 'true' {
                $!submit = True;
            }
        }
        if @data {
            @!data-order = @data.map({ .key => parse-lang-values(.value, "result $!name") });
            %!data-lookup = @!data-order;
        }
    }


    method data(--> Hash) { %!data-lookup }

    method data-ordered(--> Array) { @!data-order }

    method is-submit(--> Bool) { $!submit }
    method is-result-view(--> Bool) { $!result-view }

    method as-hash {
        return %(
            :data(@!data-order),
            :order($!order // 500000),
            :$!name,
            :$!type,
            :%!selector,
            :$!submit,
        )
    }

}
