use v6;
use Agrammon::Outputs::FilterGroupCollection;
use Agrammon::Formula::LogCollector;

class X::Agrammon::Outputs::Unset is Exception {
    has $.module is required;
    has $.name is required;
    method message() {
        "Use of unset output '$!name' from $!module"
    }
}

class X::Agrammon::Outputs::DuplicateInstance is Exception {
    has Str $.taxonomy-prefix is required;
    has Str $.instance-name is required;
    method message() {
        "Duplicate instance '$!instance-name' for taxonomy $!taxonomy-prefix"
    }
}

class X::Agrammon::Ouputs::FiltersWithoutFilterSet is Exception {
    has Str $.taxonomy-prefix is required;
    method message() {
        "Cannot create instance with filters without also providing filter set"
    }
}

class X::Agrammon::Outputs::IsMultiInstance is Exception {
    has $.module is required;
    has $.name is required;
    method message() {
        "Cannot access '$!name' from $!module as a single value, because it is in a multi-instance module"
    }
}

class X::Agrammon::Outputs::IsSingleInstance is Exception {
    has $.module is required;
    has $.name is required;
    method message() {
        "Cannot access '$!name' from $!module as a sum, because it is in a single-instance module"
    }
}

class X::Agrammon::Outputs::NotDeclaredMultiInstance is Exception {
    has $.module;
    method message() {
        "Must declare $!module as multi-instance before adding instances"
    }
}

role Agrammon::Outputs::SingleOutputStorage {
    has %!outputs;

    method add-output(Str $module, Str $name, Any $value) {
        %!outputs{$module}{$name} = $value;
    }
}

class Agrammon::Outputs { ... }

class Agrammon::Outputs::Instance does Agrammon::Outputs::SingleOutputStorage {
    has Str $.taxonomy-prefix is required;
    has Str $.instance-name is required;
    has %.filters;
    has $.filter-set;
    has Agrammon::Outputs $.parent is required;

    method get-output(Str $module, Str $name) {
        my $module-outputs := %!outputs{$module};
        $module-outputs{$name}:exists
            ?? $module-outputs{$name}
            !! self!output-fallback($module, $name)
    }

    method !output-fallback(Str $module, Str $name) {
        CATCH {
            when X::Agrammon::Outputs::IsMultiInstance {
                # Was set in another instance, but not in this one. Should never be
                # able to happen, but handle it just in case.
                die X::Agrammon::Outputs::Unset.new(:$module, :$name);
            }
        }
        $!parent.get-output($module, $name)
    }

    method get-output-hash() {
        %!outputs
    }
}

class Agrammon::Outputs does Agrammon::Outputs::SingleOutputStorage {
    has %!instances;
    has Agrammon::Formula::LogCollector $.log-collector .= new;

    method declare-multi-instance(Str $taxonomy-prefix --> Nil) {
        %!instances{$taxonomy-prefix} //= {};
    }

    method new-instance(Str $taxonomy-prefix, Str $instance-name, :%filters,
                        :$filter-set --> Agrammon::Outputs::Instance) {
        without %!instances{$taxonomy-prefix} {
            die X::Agrammon::Outputs::NotDeclaredMultiInstance.new(module => $taxonomy-prefix);
        }
        with %!instances{$taxonomy-prefix}{$instance-name} {
            die X::Agrammon::Outputs::DuplicateInstance.new(:$taxonomy-prefix, :$instance-name);
        }
        if %filters && !$filter-set {
            die X::Agrammon::Ouputs::FiltersWithoutFilterSet.new(:$taxonomy-prefix);
        }
        given Agrammon::Outputs::Instance.new(:$taxonomy-prefix, :$instance-name, :parent(self), :%filters, :$filter-set) -> $instance {
            %!instances{$taxonomy-prefix}{$instance-name} = $instance;
            return $instance;
        }
    }

    method get-output(Str $module, Str $name) {
        my $module-outputs := %!outputs{$module};
        $module-outputs{$name}:exists
            ?? $module-outputs{$name}
            !! self!bad-output($module, $name);
    }

    method !bad-output(Str $module, Str $name) {
        with self.find-instances($module) {
            die X::Agrammon::Outputs::IsMultiInstance.new(:$module, :$name);
        }
        else {
            die X::Agrammon::Outputs::Unset.new(:$module, :$name);
        }
    }

    method get-sum(Str $module, Str $name) {
        with self.find-instances($module) {
            Agrammon::Outputs::FilterGroupCollection.from-filter-to-value-pairs:
                .values.map({ .filters => .get-output($module, $name) }),
                :provenance(set(.values.map(*.filter-set)))
        }
        else {
            # Make sure it's not a bogus use of single-instance symbol,
            self.get-output($module, $name);
            die X::Agrammon::Outputs::IsSingleInstance.new(:$module, :$name);
            CATCH {
                when X::Agrammon::Outputs::Unset {
                    return 0;
                }
            }
        }
    }

    method find-instances(Str $module) {
        my $start = $module.chars;
        while $start.defined {
            .return with %!instances{$module.substr(0, $start)};
            $start = $module.rindex('::', $start - 1);
        }
        Nil
    }

    method get-outputs-hash() {
        %( flat %!outputs, %!instances.map({ .key => [.value.map({ .key => .value.get-output-hash })] }) )
    }
}
