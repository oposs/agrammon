use v6;

use Agrammon::LanguageParser;

class Agrammon::Model::Result {
    has Str $.name;
    has Str $.type;
    has %.selector{Str};
    has @!data-order;
    has %!data-lookup;
    has Str $._order;
    has Bool $!submit = False;

    submethod TWEAK( :$submit, :@data --> Nil) {
        with $submit {
            if .lc eq 'true' {
                $!submit = True;
            }
        }
        if @data {
            @!data-order = @data.map({ .key => parse-lang-values(.value) });
            %!data-lookup = @!data-order;
        }
    }

    
    method data(--> Hash) { %!data-lookup }

    method data-ordered(--> Array) { @!data-order }

    method is-submit(--> Bool) { $!submit }

    method as-hash {
        return %(
            :data(@!data-order),
            :_order($!_order // 500000),
            :$!name,
            :$!type,
            :%!selector,
            :$!submit,
        )
    }

}
