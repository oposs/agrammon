use v6;

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

    #| Get a hash mapping single instance modules to a hash of their inputs,
    #| and multi-instance modules to a list of pairs, where the key is the
    #| instance ID and the value is the inputs for that instance.
    method all-inputs() {
        %(flat %!single-inputs, %!multi-input-lists.map({ .key => [.value.map({ .instance-id => .all-inputs })] }))
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
    has $.sum;
    has Str $.taxonomy;
    has Str $.instance-id;
    has Str $.input-name;
    method message() {
        "$!what.tclc() sums to $!sum instead of 100 for instance $!instance-id of $!input-name in $!taxonomy"
    }
}

class X::Agrammon::Inputs::Distribution::MissingDistributionInput is Exception {
    has $.taxonomy;
    method message() {
        "Flattened or branched taxonomy $!taxonomy has no input field defined to distribute"
    }
}

class X::Agrammon::Inputs::Distribution::MissingDistributionValue is Exception {
    has $.taxonomy;
    has $.input-name;
    method message() {
        "No input value for '$!input-name' of $!taxonomy, which is used for flattening or branching"
    }
}

class X::Agrammon::Inputs::Distribution::BadBranchMatrix is Exception {
    has Str $.taxonomy;
    has Str $.instance-id;
    has Str $.input-name-a;
    has Str $.input-name-b;
    has Int $.expected-rows;
    has Int $.expected-cols;
    has @.bad-matrix;
    method message() {
        "Bad matrix '@!bad-matrix.perl()' for $!instance-id of $!input-name-a/$!input-name-b in $!taxonomy; " ~
                "expected $!expected-rows rows and $!expected-cols columns"
    }
}

#| A set of inputs, some of which may be a statistical distribution through either the
#| flattening or branching approach. Can produce an C<Agrammon::Inputs> object given a
#| model (the model being needed to understand which input to distribute).
class Agrammon::Inputs::Distribution does Agrammon::Inputs::Storage {
    #| The value to place into an input when we produce a distribution.
    my class DistributionProductKey {
        has Str $.sub-taxonomy is required;
        has Str $.input-name is required;
        has $.value is required;
    }

    #| A member of the product calculation for a generated input. This abstracts the
    #| differences between a flattened input (sets a single input as the "key") and
    #| a branched input (which sets two).
    my class DistributionProductElement {
        has DistributionProductKey @.values is required;
        has $.percentage is required;
    }

    #| The things flattened and branched inputs have in common.
    my role Distributable {
        method distributes-input(Str $sub-taxonomy, Str $name --> Bool) { ... }
        method distribution-products(--> Iterable) { ... }
    }

    #| A flattened input, with details of the distribution.
    my class Flattened does Distributable {
        has $.sub-taxonomy;
        has $.input-name;
        has %.value-percentages;
        method distributes-input(Str $sub-taxonomy, Str $name --> Bool) {
            $sub-taxonomy eq $!sub-taxonomy && $name eq $!input-name
        }
        method distribution-products(--> Iterable) {
            %!value-percentages.kv.map: -> $value, $percentage {
                DistributionProductElement.new:
                        :values(DistributionProductKey.new(:$!sub-taxonomy, :$!input-name, :$value)),
                        :$percentage
                if $percentage # don't add empty instances
            }
        }
    }

    #| A branched input, with details of the matrix.
    my class Branched does Distributable {
        has $.sub-taxonomy-a;
        has $.input-name-a;
        has @.input-values-a;
        has $.sub-taxonomy-b;
        has $.input-name-b;
        has @.input-values-b;
        has @.matrix;
        method distributes-input(Str $sub-taxonomy, Str $name --> Bool) {
            $sub-taxonomy eq $!sub-taxonomy-a && $name eq $!input-name-a ||
                    $sub-taxonomy eq $!sub-taxonomy-b && $name eq $!input-name-b
        }
        method distribution-products(--> Iterable) {
            gather for @!input-values-a.kv -> $i, $value-a {
                for @!input-values-b.kv -> $j, $value-b {
                    my $percentage = @!matrix[$i;$j];
                    take DistributionProductElement.new:
                        values => (
                            DistributionProductKey.new(:sub-taxonomy($!sub-taxonomy-a), :input-name($!input-name-a), :value($value-a)),
                            DistributionProductKey.new(:sub-taxonomy($!sub-taxonomy-b), :input-name($!input-name-b), :value($value-b))
                        ),
                        :$percentage
                    if $percentage # don't add empty instances
                }
            }
        }
    }

    has %!distributed-by-taxonomy;

    method add-multi-input-flattened(Str $taxonomy, Str $instance-id, Str $sub-taxonomy,
            Str $input-name, %value-percentages --> Nil) {
        self!ensure-no-dupe($taxonomy, $instance-id, $sub-taxonomy, $input-name);
        my $sum = %value-percentages.values.sum;
        # "fuzzy test" as users sometimes add distributions
        # calculated with other tools that don't sum exactly to 100
        unless ($sum - 100) < 0.0001 {
            die X::Agrammon::Inputs::Distribution::BadSum.new:
                    :what('flattened values'),
                    :$sum,
                    :taxonomy($taxonomy ~ ("::$sub-taxonomy" if $sub-taxonomy)),
                    :$instance-id, :$input-name;
        }
        %!distributed-by-taxonomy{$taxonomy}{$instance-id}.push: Flattened.new:
                :$sub-taxonomy, :$input-name, :%value-percentages;
    }

    method add-multi-input-branched(Str $taxonomy, Str $instance-id,
            Str $sub-taxonomy-a, Str $input-name-a, @input-values-a,
            Str $sub-taxonomy-b, Str $input-name-b, @input-values-b,
            @matrix --> Nil) {
        self!ensure-no-dupe($taxonomy, $instance-id, $sub-taxonomy-a, $input-name-a);
        self!ensure-no-dupe($taxonomy, $instance-id, $sub-taxonomy-b, $input-name-b);
        unless @matrix.elems == @input-values-a && all(@matrix>>.elems) == @input-values-b {
            die X::Agrammon::Inputs::Distribution::BadBranchMatrix.new:
                :$taxonomy, :$instance-id, :$input-name-a, :$input-name-b,
                :expected-rows(@input-values-a.elems), :expected-cols(@input-values-b.elems),
                :bad-matrix(@matrix);
        }
        my $sum = @matrix.map(*.sum).sum;
        # "fuzzy test" as users sometimes add distributions
        # calculated with other tools that don't sum exactly to 100
        unless ($sum - 100) < 0.0001 {
            die X::Agrammon::Inputs::Distribution::BadSum.new:
                    :what('branch matrix'),
                    :$sum,
                    :taxonomy(
                        $taxonomy ~ ("::$sub-taxonomy-a" if $sub-taxonomy-a)
                        ~ '/' ~
                        $taxonomy ~ ("::$sub-taxonomy-b" if $sub-taxonomy-b)
                    ),
                    :$instance-id, :input-name("$input-name-a/$input-name-b");
        }
        %!distributed-by-taxonomy{$taxonomy}{$instance-id}.push: Branched.new:
                :$sub-taxonomy-a, :$input-name-a, :@input-values-a,
                :$sub-taxonomy-b, :$input-name-b, :@input-values-b, :@matrix;
    }

    method !ensure-no-dupe(Str $taxonomy, Str $instance-id, Str $sub-taxonomy, Str $input-name --> Nil) {
        if %!distributed-by-taxonomy{$taxonomy}{$instance-id} -> @check {
            with @check.first(*.distributes-input($sub-taxonomy, $input-name)) {
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

    #| Produces an Agrammon::Inputs where instances are synthesized based on branching
    #| and flattening. The %dist-map parameter indicates which input(s) are to have
    #| their total values distributed over the flattening/branching inputs; it is
    #| expected to be a hash whose keys are the taxonomy of multi-module we are to
    #| produce instances of, and the values are a list of fully-qualified inputs that
    #| are to be distributed.
    method to-inputs(%dist-map --> Agrammon::Inputs) {
        my $inputs = Agrammon::Inputs.new(:$!simulation-name, :$!dataset-id);
        for %!distributed-by-taxonomy.kv -> $taxonomy, %instances {
            with %dist-map{$taxonomy} -> @distribute-over {
                for %instances.kv -> $instance-id, @distribute {
                    self!distribute($taxonomy, $instance-id, @distribute-over, @distribute, $inputs);
                }
            }
            else {
                die X::Agrammon::Inputs::Distribution::MissingDistributionInput.new(:$taxonomy);
            }
        }
        for %!multi-input-lookup.kv -> $taxonomy, %instances {
            for %instances.kv -> $instance-id, $instance {
                self!copy-instance-input($taxonomy, $instance-id, $instance!input-hash(), $inputs);
            }
        }
        for %!single-inputs.kv -> $taxonomy, %inputs {
            for %inputs.kv -> $input-name, $value {
                $inputs.add-single-input($taxonomy, $input-name, $value);
            }
        }
        return $inputs;
    }

    method !distribute(Str $taxonomy, Str $instance-id, @distribute-over, @distribute,
            Agrammon::Inputs $target --> Nil) {
        # Get instance input data, and remove the instance we'll distribute.
        my $dist-instance = %!multi-input-lookup{$taxonomy}{$instance-id};
        my %instance-input := $dist-instance ?? $dist-instance!input-hash !! {};
        %!multi-input-lookup{$taxonomy}{$instance-id}:delete;
        if %!multi-input-lists{$taxonomy} -> @filter {
            @filter .= grep(* !=== $dist-instance);
        }

        # Get details of the inputs we distribute over, and remove them.
        my class DistributableValue {
            has Str $.dist-name is required;
            has Str $.dist-sub-taxonomy is required;
            has Int $.dist-total is required;
        }
        my @distributable-values;
        for @distribute-over -> $dist-over {
            my $dist-name = $dist-over.substr($dist-over.rindex('::') + 2);
            my $dist-taxonomy = $dist-over.substr(0, $dist-over.chars - ($dist-name.chars + 2));
            my $dist-sub-taxonomy = $dist-taxonomy eq $taxonomy
                    ?? ''
                    !! $dist-taxonomy.substr($taxonomy.chars + 2);
            my $dist-total = do with %instance-input{$dist-taxonomy}{$dist-name}:delete {
                $_
            }
            else {
                die X::Agrammon::Inputs::Distribution::MissingDistributionValue.new:
                        taxonomy => $dist-taxonomy, input-name => $dist-name;
            }
            @distributable-values.push: DistributableValue.new(:$dist-name, :$dist-sub-taxonomy, :$dist-total);
        }

        # Create distributed instances.
        my $instance-number = 1;
        for cross(@distribute.map(*.distribution-products)) -> $products {
            my $dist-instance-id = "$instance-id {$instance-number++}";
            my $comp-percentage = [*] $products.map(*.percentage / 100);
            for @distributable-values {
                $target.add-multi-input($taxonomy, $dist-instance-id, .dist-sub-taxonomy, .dist-name,
                        ($comp-percentage * .dist-total).narrow);
            }
            for flat $products.map(*.values) {
                $target.add-multi-input($taxonomy, $dist-instance-id, .sub-taxonomy,
                        .input-name, .value);
            }
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
