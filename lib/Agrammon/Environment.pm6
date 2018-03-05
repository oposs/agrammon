class Agrammon::Environment {
    my class Scope {
        has %.variables;
        has Scope $.outer;

        method declare(Str $name --> Any) is rw {
            %!variables{$name} = Any;
        }

        method lookup(Str $name --> Any) is rw {
            if %!variables{$name}:exists {
                %!variables{$name}
            }
            orwith $!outer {
                .lookup($name)
            }
            else {
                die "No such variable '$name'"
            }
        }
    }

    has %.input;
    has %.technical;
    has %.output;
    has Scope $.scope .= new;

    method enter-scope(--> Nil) {
        $!scope = Scope.new(outer => $!scope)
    }

    method leave-scope(--> Nil) {
        $!scope .= outer;
    }
}
