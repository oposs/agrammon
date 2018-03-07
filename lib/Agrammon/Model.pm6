use v6;
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

class Agrammon::Model {
    has IO::Path $.path;
    has Agrammon::Model::Module @.evaluation-order;
  
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

    method load($module-name, :%pending, :%loaded) {

        # trying to load module while already loading it
        die X::Agrammon::Model::CircularModel.new(:module($module-name))
            if %pending{$module-name}:exists;

        # module has already been loaded
        return if %loaded{$module-name};

        %pending{$module-name} = True;
        my $module = self.load-module($module-name);
        my $parent = $module.parent;
        my @externals = $module.external;
        for @externals -> $external {
            my $external-name = $external.name;
            my $include = $parent ?? $parent ~ '::' ~ $external-name
                                  !! $external-name;
            self.load($include, :%pending, :%loaded);
        }
        @!evaluation-order.push($module);
        %loaded{$module-name} = True;
        %pending{$module-name}:delete;
    }

    method dump {
        my Str $output;
        for @!evaluation-order.reverse {
            $output ~= $_.taxonomy ~ "\n";
        }
        return $output;
    }

}
