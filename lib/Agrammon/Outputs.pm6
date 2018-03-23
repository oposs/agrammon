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
    has Agrammon::Outputs $.parent is required;

    method get-output(Str $module, Str $name) {
        if %!outputs{$module}{$name}:exists {
            %!outputs{$module}{$name}
        }
        else {
            return $!parent.get-output($module, $name);
            CATCH {
                when X::Agrammon::Outputs::IsMultiInstance {
                    # Was set in another instance, but not in this one. Should never be
                    # able to happen, but handle it just in case.
                    die X::Agrammon::Outputs::Unset.new(:$module, :$name);
                }
            }
        }
    }

    method get-output-hash() {
        %!outputs
    }
}

class Agrammon::Outputs does Agrammon::Outputs::SingleOutputStorage {
    has %!instances;

    method new-instance(Str $taxonomy-prefix, Str $instance-name --> Agrammon::Outputs::Instance) {
        with %!instances{$taxonomy-prefix}{$instance-name} {
            die X::Agrammon::Outputs::DuplicateInstance.new(:$taxonomy-prefix, :$instance-name);
        }
        given Agrammon::Outputs::Instance.new(:$taxonomy-prefix, :$instance-name, :parent(self)) -> $instance {
            %!instances{$taxonomy-prefix}{$instance-name} = $instance;
            return $instance;
        }
    }

    method get-output(Str $module, Str $name) {
        if %!outputs{$module}{$name}:exists {
            return %!outputs{$module}{$name};
        }
        orwith self!find-instances($module) {
            .get-output($module, $name) with .values.first; # Will throw if symbol fully unknown
            die X::Agrammon::Outputs::IsMultiInstance.new(:$module, :$name);
        }
        die X::Agrammon::Outputs::Unset.new(:$module, :$name);
    }

    method get-sum(Str $module, Str $name) {
        with self!find-instances($module) {
            [+] .values.map({ .get-output($module, $name) })
        }
        else {
            # Make sure it's not a bogus use of single-instance symbol,
            self.get-output($module, $name);
            die X::Agrammon::Outputs::IsSingleInstance.new(:$module, :$name);
        }
    }

    method !find-instances(Str $module) {
        for reverse [\~] $module.split(/<?before '::'>/) -> $maybe-module {
            .return with %!instances{$maybe-module};
        }
        return Nil;
    }

    method get-outputs-hash() {
        %( flat %!outputs, %!instances.map({ .key => [.value.map({ .key => .value.get-output-hash })] }) )
    }
}
