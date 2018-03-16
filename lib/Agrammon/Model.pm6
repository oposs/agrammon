use v6;
use Agrammon::Inputs;
use Agrammon::ModuleBuilder;
use Agrammon::ModuleParser;
use Agrammon::Model::Module;

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

        method run(:$input!, :%technical!) {
            my %outputs;
            my $*IN-MULTI = False;
            self!run-internal($input, %technical, %outputs);
            return %outputs;
        }

        method !run-internal($input, %technical, %outputs --> Nil) {
            my $tax = $!module.taxonomy;
            if $!module.is-multi {
                my $*IN-MULTI = True;
                for $!module.output {
                    %outputs{$tax}{.name} = [];
                }
                for $input.inputs-list-for($tax) -> $multi-input {
                    self!run-as-single($multi-input, %technical, %outputs);
                }
            }
            else {
                self!run-as-single($input, %technical, %outputs);
            }
        }

        method !run-as-single($input, %technical, %outputs --> Nil) {
            for @!dependencies -> $dep {
                $dep!run-internal($input, %technical, %outputs);
            }

            my $tax = $!module.taxonomy;
            my %module-input = $input.input-hash-for($tax);
            my %module-technical = $!module.technical.map({ .name => .value });
            with %technical{$tax} -> %override {
                %module-technical ,= %override;
            }
            for $!module.output {
                my $env = Agrammon::Environment.new(
                    input => %module-input,
                    technical => %module-technical,
                    output => %outputs
                );
                my $result = .formula.evaluate($env);
                if $*IN-MULTI {
                    push (%outputs{$tax}{.name} //= []), $result;
                }
                else {
                    %outputs{$tax}{.name} = $result;
                }
            }
        }
    }

    has IO::Path $.path;
    has Agrammon::Model::Module @.evaluation-order;
    has ModuleRunner $!entry-point;
  
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
            return Agrammon::ModuleParser.parsefile(
                $file,
                actions => Agrammon::ModuleBuilder
            ).ast;
            CATCH {
                die "Failed to parse module $file:\n$_";
            }
        }
    }

    method load($module-name --> Nil) {
        $!entry-point = self!load-internal($module-name);
        self!sanity-check();
    }

    method !load-internal($module-name, :%pending, :%loaded --> ModuleRunner) {
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
            push @dependencies, self!load-internal($include, :%pending, :%loaded);
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

    sub normalize($module-name) {
        $module-name.subst(/'::' <.ident> '::..'/, '', :g)
    }

    method run(Agrammon::Inputs :$input!, :%technical) {
        $!entry-point.run(:$input, :%technical)
    }

    method dump {
        my Str $output;
        for @!evaluation-order.reverse {
            $output ~= $_.taxonomy ~ "\n";
        }
        return $output;
    }

}
