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
	return $!path ~ $file;
    }

    method loadModule($module-name) {
	my $file = self.module2file($module-name);
	die X::Agrammon::Model::FileNotFound.new(:file($file))    unless $file.IO.e;
	die X::Agrammon::Model::FileNotReadable.new(:file($file)) unless $file.IO.r;
	
	my $module-data = slurp($file);
	my $module = Agrammon::ModuleParser.parse(
	    $module-data,
	    actions => Agrammon::ModuleBuilder
	).ast;
	return $module;
    }

    method load($top, $debug?) {
	state %pending;

	die X::Agrammon::Model::CircularModel.new(:module($top))
	    if %pending{$top}:exists;
	%pending{$top} = 1;
	my $module = self.loadModule($top);
	my $parent = $module.parent;
	say "Loading $top" if $debug;
	my @externals = $module.external;
	for @externals -> $external {
	    my $external-name = $external.name;
	    my $include = $parent ?? $parent ~ '::' ~ $external-name
	                          !! $external-name;
	    self.load($include);
	}
	@!evaluation-order.push($module);
	%pending{$top}:delete;
    }

}
