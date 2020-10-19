use v6;
use Agrammon::Formula::Compiler;
use Agrammon::Inputs;
use Agrammon::ModuleBuilder;
use Agrammon::ModuleParser;
use Agrammon::Model::FilterSet;
use Agrammon::Model::Module;
use Agrammon::Outputs;
use Agrammon::Preprocessor;

class X::Agrammon::Model::FileNotFound is Exception {
    has $.file;
    method message() {
        "Model file $!file not found!";
    }
}

class X::Agrammon::Model::FileNotReadable is Exception {
    has $.file;
    method message() {
        "Model file $!file not readable!";
    }
}

class X::Agrammon::Model::CircularModel is Exception {
    has $.module;
    method message() {
        "Module $!module has circular dependency!";
    }
}

role X::Agrammon::Model::BadFormula is Exception {
    has $.module;
    has $.output;
    method !prefix() {
        "Output '$!output' of module '$!module' "
    }
}

class X::Agrammon::Model::InvalidInput does X::Agrammon::Model::BadFormula {
    has $.input;
    method message() {
        self!prefix ~ "uses undeclared input '$!input'"
    }
}

class X::Agrammon::Model::InvalidTechnical does X::Agrammon::Model::BadFormula {
    has $.technical;
    method message() {
        self!prefix ~ "uses undeclared technical '$!technical'"
    }
}

class X::Agrammon::Model::InvalidOutputSymbol does X::Agrammon::Model::BadFormula {
    has $.from;
    has $.symbol;
    method message() {
        self!prefix ~ "uses undeclared output '$!symbol' from $!from"
    }
}

class X::Agrammon::Model::InvalidOutputModule does X::Agrammon::Model::BadFormula {
    has $.from;
    has $.symbol;
    method message() {
        self!prefix ~ "tries to use '$!symbol' from unknown module $!from (missing external?)"
    }
}

class Agrammon::Model {
    my class ModuleRunner {
        has Agrammon::Model::Module $.module;
        has ModuleRunner @.dependencies;
        has Agrammon::Model::FilterSet $!filter-set;

        submethod TWEAK(--> Nil) {
            if $!module.is-multi {
                $!filter-set .= new(:$!module, :dependencies(@!dependencies.map(*.module)));
            }
        }

        method run(:$input!, :%technical!) {
            my $outputs = Agrammon::Outputs.new;
            my %run-already;
            self!run-internal($input, %technical, $outputs, %run-already);
            return $outputs;
        }

        method !run-internal($input, %technical, $outputs, %run-already --> Nil) {
            my $tax = $!module.taxonomy;
            return if %run-already{$tax};
            if $!module.is-multi {
                # Run each module once by having a fresh copy of the run-already hash
                # instance. Then mark the whole graph as having run.
                $outputs.declare-multi-instance($tax);
                for $input.inputs-list-for($tax) -> $multi-input {
                    my %filters := $!filter-set.filters-for($multi-input);
                    my $multi-output = $outputs.new-instance($tax, $multi-input.instance-id, :%filters);
                    self!run-as-single($multi-input, %technical, $multi-output, %run-already.clone);
                }
                self!mark-multi-run(%run-already);
            }
            else {
                self!run-as-single($input, %technical, $outputs, %run-already);
                %run-already{$tax} = True;
            }
        }

        method !run-as-single($input, %technical, $outputs, %run-already --> Nil) {
            for @!dependencies -> $dep {
                $dep!run-internal($input, %technical, $outputs, %run-already);
            }

            my $tax = $!module.taxonomy;
            my $env = Agrammon::Environment.new(
                input => $input.input-hash-for($tax),
                input-defaults => $!module.input-defaults,
                technical => $!module.technical-hash,
                technical-override => %technical{$tax},
                output => $outputs
            );
            for $!module.output -> $output {
                my $name = $output.name;
                $outputs.add-output($tax, $name, $output.compiled-formula()($env));
                CONTROL {
                    when CX::Warn {
                        note "Warning evaluating output '$name' in $tax: $_.message()";
                        .resume;
                    }
                }
                CATCH {
                    die "Died when evaluating formula '$name' in $tax: $_.message()";
                }
            }
        }

        method !mark-multi-run(%run-already --> Nil) {
            %run-already{$!module.taxonomy} = True;
            for @!dependencies -> $dep {
                $dep!mark-multi-run(%run-already);
            }
        }
    }

    has IO::Path $.path;
    has %.preprocessor-options;
    has Agrammon::Model::Module @.evaluation-order;
    has ModuleRunner $!entry-point;
    has %!output-unit-cache;
    has %!output-print-cache;
    has %!output-format-cache;
    has %!output-labels-cache;
    has %!output-order-cache;
    has $!distribution-map-cache;
  
    method file2module($file) {
        my $module = $file;
        $module ~~ s:g|'/'|::|;
        $module ~~ s/\.nhd$//;
        return $module;
    }

    method module2file($module) {
        my $file = $module;
        $file ~~ s:g|'::'|/|;
        $file ~= '.nhd';
        return $!path.add($file);
    }

    method load-module($module-name) {
        my $file = self.module2file($module-name);
        die X::Agrammon::Model::FileNotFound.new(:$file)    unless $file.IO.e;
        die X::Agrammon::Model::FileNotReadable.new(:$file) unless $file.IO.r;

        {
            return Agrammon::ModuleParser.parse(
                preprocess($file.slurp, %!preprocessor-options),
                actions => Agrammon::ModuleBuilder
            ).ast;
            CATCH {
                die "Failed to parse module $file:\n$_";
            }
        }
    }

    method load($module-name, :$compile-formulas = True --> Agrammon::Model) {
        $!entry-point = self!load-internal($module-name);
        self!sanity-check();
        self!compile-formulas() if $compile-formulas;
        return self;
    }

    method !load-internal($module-name, $root?, $root-module?, :%pending, :%loaded --> ModuleRunner) {
        # trying to load module while already loading it
        die X::Agrammon::Model::CircularModel.new(:module($module-name))
            if %pending{$module-name}:exists;

        # module has already been loaded
        return $_ with %loaded{$module-name};

        %pending{$module-name} = True;
        my $module = self.load-module($module-name);
        given $module.taxonomy -> $tax {
            die "Wrong taxonomy '$tax' in $module-name" unless $tax eq $module-name;
        }
        my $instance-root = $root;
        $instance-root //= $module.taxonomy if $module.is-multi;
        my $gui-root-module = $root-module;
        $gui-root-module = $module if $module.gui;
        $module.set-instance-root($instance-root) if $instance-root;
        $module.set-gui-root($gui-root-module) if $gui-root-module;
        my $parent = $module.parent;
        my @externals = $module.external;
        my @dependencies;
        for @externals -> $external {
            my $external-name = $external.name;
            my $include = $external-name.starts-with('::')
                ?? $external-name.substr(2)
                !! $parent
                    ?? normalize($parent ~ '::' ~ $external-name)
                    !! $external-name;
            push @dependencies, self!load-internal($include, $instance-root, $gui-root-module, :%pending, :%loaded);
        }
        @!evaluation-order.push($module);
        %pending{$module-name}:delete;

        my $evaluator = ModuleRunner.new(:$module, :@dependencies);
        %loaded{$module-name} = $evaluator;
        return $evaluator;
    }

    # Perform an abstract interpretation of the model, tracking outputs set,
    # in order to check for unknown outputs and outputs used too early.
    method !sanity-check() {
        my %known-outputs;
        for @!evaluation-order -> $module {
            my %known-input := set $module.input.map(*.name);
            my %known-technical := set $module.technical.map(*.name);
            my $tax = $module.taxonomy;
            %known-outputs{$tax} = {};

            for $module.output -> $output (:$name, :$formula, *%) {
                with $formula.input-used.first(* !(elem) %known-input) {
                    die X::Agrammon::Model::InvalidInput.new(
                        module => $module.taxonomy,
                        output => $output.name,
                        input => $_
                    );
                }

                with $formula.technical-used.first(* !(elem) %known-technical) {
                    die X::Agrammon::Model::InvalidTechnical.new(
                        module => $module.taxonomy,
                        output => $output.name,
                        technical => $_
                    );
                }

                for $formula.output-used -> $sym {
                    with %known-outputs{$sym.module} -> %module-outputs {
                        without %module-outputs{$sym.symbol} {
                            die X::Agrammon::Model::InvalidOutputSymbol.new(
                                module => $module.taxonomy,
                                output => $output.name,
                                from => $sym.module,
                                symbol => $sym.symbol
                            );
                        }
                    }
                    else {
                        die X::Agrammon::Model::InvalidOutputModule.new(
                            module => $module.taxonomy,
                            output => $output.name,
                            from => $sym.module,
                            symbol => $sym.symbol
                        );
                    }
                }

                %known-outputs{$tax}{$name} = True;
            }
        }
    }

    method !compile-formulas() {
        my @output-order;
        my @formula-sources;
        for @!evaluation-order.map(*.output).flat -> $output {
            push @output-order, $output;
            push @formula-sources, compile-formula-to-source($output.formula);
        }
        use MONKEY-SEE-NO-EVAL;
        for flat @output-order Z EVAL(@formula-sources.join(',')) -> $output, $compiled {
            $output.compiled-formula = $compiled;
        }
    }

    sub normalize($module-name) {
        $module-name.subst(/'::' <.ident> '::..'/, '', :g)
    }

    method run(Agrammon::Inputs :$input!, :%technical --> Agrammon::Outputs) {
        $!entry-point.run(:$input, :%technical)
    }

    method dump {
        my Str $output;
        for @!evaluation-order.reverse {
            $output ~= $_.taxonomy ~ "\n";
        }
        return $output;
    }

    method output-unit(Str $module, Str $output, Str $lang --> Str) {
        %!output-unit-cache ||= @!evaluation-order.map({
            .taxonomy => %(.output.map({ .name => .units }))
        });
        return %!output-unit-cache{$module}{$output}{$lang} // ''
    }

    method output-units(Str $module, Str $output) {
        %!output-unit-cache ||= @!evaluation-order.map({
            .taxonomy => %(.output.map({ .name => .units }))
        });
        return %!output-unit-cache{$module}{$output}
    }

    method output-print(Str $module, Str $output) {
        %!output-print-cache ||= @!evaluation-order.map({
            .taxonomy => %(.output.map({ .name => .print }))
        });
        return %!output-print-cache{$module}{$output} // ''
    }

    method output-format(Str $module, Str $output) {
        %!output-format-cache ||= @!evaluation-order.map({
            .taxonomy => %(.output.map({ .name => .format }))
        });
        return %!output-format-cache{$module}{$output} // ''
    }

    method output-order(Str $module, Str $output) {
        %!output-order-cache ||= @!evaluation-order.map({
            .taxonomy => %(.output.map({ .name => .order }))
        });
        return %!output-order-cache{$module}{$output} // ''
    }

    method output-labels(Str $module, Str $output) {
        %!output-labels-cache ||= @!evaluation-order.map({
            .taxonomy => %(.output.map({ .name => .labels }))
        });
        return %!output-labels-cache{$module}{$output} // ''
    }

    method distribution-map() {
        $!distribution-map-cache ||= %(gather {
            sub walk-to-instance(ModuleRunner $current) {
                if $current.module.is-multi {
                    walk-instance($current, $current.module.taxonomy);
                }
                else {
                    for $current.dependencies {
                        walk-to-instance($_);
                    }
                }
            }
            sub walk-instance(ModuleRunner $current, Str $base) {
                for $current.module.input {
                    if .is-branch {
                        take $base => $current.module.taxonomy ~ '::' ~ .name;
                        return True;
                    }
                }
                for $current.dependencies {
                    return True if walk-instance($_, $base);
                }
                return False;
            }
            walk-to-instance($!entry-point);
        });
        %$!distribution-map-cache
    }
}
