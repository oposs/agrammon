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

class X::Agrammon::Inputs::Distribution::BadSum is Exception {
    has Str $.what;
    has Str $.taxonomy;
    has Str $.instance-id;
    has Str $.input-name;
    method message() {
        "$!what.tclc() does not sum to 100 for instance $!instance-id of $!input-name in $!taxonomy"
    }
}

#| A set of inputs, some of which may be a statistical distribution through either the
#| flattening or branching approach. Can produce an C<Agrammon::Inputs> object given a
#| model (the model being needed to understand which input to distribute).
class Agrammon::Inputs::Distribution does Agrammon::Inputs::Storage {
    my role Distributable {
        has $.sub-taxonomy;
        method distributes-input(Str $name --> Bool) { ... }
    }

    my class Flattened does Distributable {
        has $.input-name;
        has %.value-percentages;
        method distributes-input(Str $name --> Bool) { $name eq $!input-name }
    }

    my class Branched does Distributable {
        has $.input-name-a;
        has $.input-name-b;
        has @.matrix;
        method distributes-input(Str $name --> Bool) { so $name eq $!input-name-a | $!input-name-b }
    }

    has %!distributed-by-taxonomy;

    method add-multi-input-flattened(Str $taxonomy, Str $instance-id, Str $sub-taxonomy,
            Str $input-name, %value-percentages --> Nil) {
        self!ensure-no-dupe($taxonomy, $instance-id, $sub-taxonomy, $input-name);
        unless %value-percentages.values.sum == 100 {
            die X::Agrammon::Inputs::Distribution::BadSum.new:
                    :what('flattened values'),
                    :taxonomy($taxonomy ~ ("::$sub-taxonomy" if $sub-taxonomy)),
                    :$instance-id, :$input-name;
        }
        %!distributed-by-taxonomy{$taxonomy}{$instance-id}.push: Flattened.new:
                :$sub-taxonomy, :$input-name, :%value-percentages;
    }

    method add-multi-input-branched(Str $taxonomy, Str $instance-id, Str $sub-taxonomy,
            Str $input-name-a, Str $input-name-b, @matrix --> Nil) {
        for $input-name-a, $input-name-b {
            self!ensure-no-dupe($taxonomy, $instance-id, $sub-taxonomy, $_);
        }
        unless @matrix.map(*.sum).sum == 100 {
            die X::Agrammon::Inputs::Distribution::BadSum.new:
                    :what('branch matrix'),
                    :taxonomy($taxonomy ~ ("::$sub-taxonomy" if $sub-taxonomy)),
                    :$instance-id, :input-name("$input-name-a/$input-name-b");
        }
        %!distributed-by-taxonomy{$taxonomy}{$instance-id}.push: Branched.new:
                :$sub-taxonomy, :$input-name-a, :$input-name-b, :@matrix;
    }

    method !ensure-no-dupe(Str $taxonomy, Str $instance-id, Str $sub-taxonomy, Str $input-name --> Nil) {
        if %!distributed-by-taxonomy{$taxonomy}{$instance-id} -> @check {
            with @check.first({ .sub-taxonomy eq $sub-taxonomy && .distributes-input($input-name) }) {
                when Flattened {
                    die X::Agrammon::Inputs::Distribution::AlreadyFlattened.new:
                            :taxonomy($taxonomy ~ ("::$sub-taxonomy" if $sub-taxonomy)),
                            :$instance-id, :$input-name;
                }
                when Branched {
                    die X::Agrammon::Inputs::Distribution::AlreadyBranched.new:
                            :taxonomy($taxonomy ~ ("::$sub-taxonomy" if $sub-taxonomy)),
                            :$instance-id, :$input-name;
                }
            }
        }
    }

    method to-inputs(%dist-map) {
        my $inputs = Agrammon::Inputs.new;
        for %!distributed-by-taxonomy.kv -> $taxonomy, %instances {
            for %instances.kv -> $instance-id, @distribute {
                self!distribute($taxonomy, $instance-id, %dist-map{$taxonomy}, @distribute, $inputs);
            }
        }
        return $inputs;
    }

    method !distribute(Str $taxonomy, Str $instance-id, Str $dist-over, @distribute,
            Agrammon::Inputs $target --> Nil) {
        # Get instance input data.
        my $dist-instance = %!multi-input-lookup{$taxonomy}{$instance-id};
        my %instance-input := $dist-instance!input-hash;

        # Break up distribution input value into number of parts, accounting for the values
        # being percentages.
        my $parts = @distribute.elems;
        my $dist-name = $dist-over.substr($dist-over.rindex('::') + 2);
        my $dist-taxonomy = $dist-over.substr(0, $dist-over.chars - ($dist-name.chars + 2));
        my $dist-sub-taxonomy = $dist-taxonomy eq $taxonomy
                ?? ''
                !! $dist-taxonomy.substr($taxonomy.chars + 2);
        my $dist-total = %instance-input{$dist-taxonomy}{$dist-name};
        my $per-part = $dist-total / ($parts * 100);

        # Remove the instance that we'll be distributing.
        %!multi-input-lookup{$taxonomy}{$instance-id}:delete;
        if %!multi-input-lists{$taxonomy} -> @filter {
            @filter .= grep(* !=== $dist-instance);
        }

        # Remove the distributed field.
        %instance-input{$dist-taxonomy}{$dist-name}:delete;

        # Create distributed instances.
        my @flattened = @distribute.grep(Flattened);
        my @branched = @distribute.grep(Branched);
        die "NYI" unless @flattened == 1;
        die "NYI" unless @branched == 0;
        my $instance-number = 1;
        for @flattened[0].value-percentages.sort(*.key).map(*.kv).flat -> $enum, $value {
            my $dist-instance-id = "$instance-id {$instance-number++}";
            $target.add-multi-input($taxonomy, $dist-instance-id, $dist-sub-taxonomy, $dist-name,
                    ($value * $per-part).narrow);
            $target.add-multi-input($taxonomy, $dist-instance-id, @flattened[0].sub-taxonomy,
                    @flattened[0].input-name, $enum);
            self!copy-instance-input($taxonomy, $dist-instance-id, %instance-input, $target);
        }
    }

    method !copy-instance-input($base-taxonomy, $instance-id, %input, $target) {
        for %input.kv -> $taxonomy, %taxonomy-inputs {
            my $sub-taxonomy = $taxonomy eq $base-taxonomy
                    ?? ''
                    !! $taxonomy.substr($base-taxonomy.chars + 2);
            for %taxonomy-inputs.kv -> $name, $value {
                $target.add-multi-input($base-taxonomy, $instance-id, $sub-taxonomy, $name, $value);
            }
        }
    }

    method !input-hash() {
        %!single-inputs
    }
}
