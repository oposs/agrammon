class X::Agrammon::Inputs::AlreadySingle is Exception {
    has Str $.taxonomy;
    method message() {
        "Taxonomy $!taxonomy already has single-instance data; cannot add multi-instance data"
    }
}

class X::Agrammon::Inputs::AlreadyMulti is Exception {
    has Str $.taxonomy;
    method message() {
        "Taxonomy $!taxonomy already has multi-instance data; cannot add single-instance data"
    }
}

class X::Agrammon::Inputs::Single is Exception {
    has Str $.taxonomy;
    method message() {
        "Cannot get multi-instance input for taxonomy $!taxonomy as it has single-instance data"
    }
}

class X::Agrammon::Inputs::Multi is Exception {
    has Str $.taxonomy;
    method message() {
        "Cannot get single-instance input for taxonomy $!taxonomy as it has multi-instance data"
    }
}

#| Implements storage of simple (not-flattening, non-branched) input data.
role Agrammon::Inputs::Storage {
    has Str $.simulation-name;
    has Str $.dataset-id;
    has Str $.instance-id;
    has %!single-inputs;
    has %!multi-input-lists;
    has %!multi-input-lookup;

    #| Adds an input for a single-instance module.
    method add-single-input(Str $taxonomy, Str $input-name, Any $value --> Nil) {
        with %!multi-input-lists{$taxonomy} {
            die X::Agrammon::Inputs::AlreadyMulti.new(:$taxonomy);
        }
        %!single-inputs{$taxonomy}{$input-name} = $value;
    }

    #| Adds an input for a multi-instance module.
    method add-multi-input(Str $taxonomy, Str $instance-id, Str $sub-taxonomy,
            Str $input-name, Any $value --> Nil) {
        with %!single-inputs{$taxonomy} {
            die X::Agrammon::Inputs::AlreadySingle.new(:$taxonomy);
        }
        my $input;
        with %!multi-input-lookup{$taxonomy}{$instance-id} {
            $input = $_;
        }
        else {
            $input = self.new(:$instance-id, :$!simulation-name, :$!dataset-id);
            %!multi-input-lookup{$taxonomy}{$instance-id} = $input;
            push %!multi-input-lists{$taxonomy}, $input;
        }
        my $qualified = $taxonomy ~ ("::$sub-taxonomy" if $sub-taxonomy);
        $input.add-single-input($qualified, $input-name, $value);
    }
}

#| A set of inputs ready for evaluation.
class Agrammon::Inputs does Agrammon::Inputs::Storage {
    #| Gets a hash of inputs for a single-instance module.
    method input-hash-for(Str $taxonomy --> Hash) {
        with %!multi-input-lists{$taxonomy} {
            die X::Agrammon::Inputs::Multi.new(:$taxonomy);
        }
        %!single-inputs{$taxonomy} // {}
    }

    #| Gets a list of Agrammon::Input objects for a multi-instance module.
    #| These can be iterated over, and have C<input-hash-for> called on them
    #| to get the inputs for that module and nested ones.
    method inputs-list-for(Str $taxonomy --> List) {
        with %!single-inputs{$taxonomy} {
            die X::Agrammon::Inputs::Single.new(:$taxonomy);
        }
        @(%!multi-input-lists{$taxonomy} // [])
    }
}

class X::Agrammon::Inputs::Distribution::AlreadyFlattened is Exception {
    has Str $.taxonomy;
    has Str $.instance-id;
    has Str $.input-name;
    method message() {
        "Already have flattened data for instance $!instance-id of $!input-name in $!taxonomy"
    }
}

class X::Agrammon::Inputs::Distribution::AlreadyBranched is Exception {
    has Str $.taxonomy;
    has Str $.instance-id;
    has Str $.input-name;
    method message() {
        "Already have branched data for instance $!instance-id of $!input-name in $!taxonomy"
    }
}

#| A set of inputs, some of which may be a statistical distribution through either the
#| flattening or branching approach. Can produce an C<Agrammon::Inputs> object given a
#| model (the model being needed to understand which input to distribute).
class Agrammon::Inputs::Distribution does Agrammon::Inputs::Storage {
    my class Flattened {
        has $.instance-id;
        has $.sub-taxonomy;
        has $.input-name;
        has %.value-percentages;
    }

    my class Branched {
        has $.instance-id;
        has $.sub-taxonomy;
        has $.input-name-a;
        has $.input-name-b;
        has @.matrix;
    }

    has Array[Flattened] %!flattened-by-taxonomy;
    has Array[Branched] %!branched-by-taxonomy;

    method add-multi-input-flattened(Str $taxonomy, Str $instance-id, Str $sub-taxonomy,
            Str $input-name, %value-percentages --> Nil) {
        self!ensure-no-dupe($taxonomy, $instance-id, $sub-taxonomy, $input-name);
        %!flattened-by-taxonomy{$taxonomy}.push: Flattened.new:
                :$instance-id, :$sub-taxonomy, :$input-name, :%value-percentages;
    }

    method add-multi-input-branched(Str $taxonomy, Str $instance-id, Str $sub-taxonomy,
            Str $input-name-a, Str $input-name-b, @matrix --> Nil) {
        for $input-name-a, $input-name-b {
            self!ensure-no-dupe($taxonomy, $instance-id, $sub-taxonomy, $_);
        }
        %!branched-by-taxonomy{$taxonomy}.push: Branched.new:
                :$instance-id, :$sub-taxonomy, :$input-name-a, :$input-name-b, :@matrix;
    }

    method !ensure-no-dupe(Str $taxonomy, Str $instance-id, Str $sub-taxonomy, Str $input-name --> Nil) {
        if %!flattened-by-taxonomy{$taxonomy} -> @check {
            with @check.first({ .instance-id eq $instance-id && .sub-taxonomy eq $sub-taxonomy &&
                    .input-name eq $input-name }) {
                die X::Agrammon::Inputs::Distribution::AlreadyFlattened.new:
                        :taxonomy($taxonomy ~ ("::$sub-taxonomy" if $sub-taxonomy)),
                        :$instance-id, :$input-name;
            }
        }
        if %!branched-by-taxonomy{$taxonomy} -> @check {
            with @check.first({ .instance-id eq $instance-id && .sub-taxonomy eq $sub-taxonomy &&
                    .input-name-a | .input-name-b eq $input-name }) {
                die X::Agrammon::Inputs::Distribution::AlreadyBranched.new:
                        :taxonomy($taxonomy ~ ("::$sub-taxonomy" if $sub-taxonomy)),
                        :$instance-id, :$input-name;
            }
        }
    }
}
