use v6;
use Agrammon::Model;
use Test;
plan 3;

subtest "Helper function" => {
    
    my $path = $*PROGRAM.parent.add('test-data/');
    ok my $model = Agrammon::Model.new(path => $path);
    given 'Livestock::DairyCow::Excretion::CMilk' -> $module-name {
	is my $file = $model.module2file($module-name),
	    $path ~ 'Livestock/DairyCow/Excretion/CMilk.nhd',
	    "module2file(): convert module $module-name to file";
    }

}


subtest "loadModule()" =>{

    my $path = $*PROGRAM.parent.add('test-data/');
    given 'CMilk' -> $module-name {
	ok my $model = Agrammon::Model.new(path => $path);
	ok my $module = $model.loadModule($module-name), "Load module $module-name";
	is $module.input[0].name, 'milk_yield', "Found input milk_yield";
    }

    given 'CMilk' -> $module-name {
	chmod 0, $path ~ $module-name ~ '.nhd';
	ok my $model = Agrammon::Model.new(path => $path);
	throws-like { my $module = $model.loadModule($module-name) },
                      X::Agrammon::Model::FileNotReadable,
                      "Cannot load module $module-name from read-only file";
	chmod 0o644, $path ~ $module-name ~ '.nhd';
    }

    given 'CMilk_notExists' -> $module-name {
	ok my $model = Agrammon::Model.new(path => $path);
	throws-like { my $module = $model.loadModule($module-name) },
                    X::Agrammon::Model::FileNotFound,
                    "Cannot load module $module-name from none-existing file";
    }

    $path = $*PROGRAM.parent.add('test-data/Models/hr-inclNOx/');
    given 'Livestock' -> $module-name {
	ok my $model = Agrammon::Model.new(path => $path);
	my $module = $model.loadModule($module-name);
	is my $parent = $module.parent, '', "Module $module-name has no parent";
	is my $name = $module.name, $module-name, "Module $module-name has name $module-name";
	}

    given 'Livestock::DairyCow::Excretion::CMilk' -> $module-name {
	ok my $model = Agrammon::Model.new(path => $path);
	my $module = $model.loadModule($module-name);
	is my $parent = $module.parent,
	    'Livestock::DairyCow::Excretion',
	    "Module $module-name has parent Livestock::DairyCow::Excretion";
	is my $name = $module.name, 'CMilk', "Module $module-name has name CMilk";
    }

}


subtest 'load()' => { 

    subtest 'Simple model loading' => {
	my $path = $*PROGRAM.parent.add('test-data/Models/test_simple/');
	my @expected = qw|
            Simple::Sub1a
            Simple::Sub1
            Simple::Sub1a
            Simple::Sub2a
            Simple::Sub2b
	    Simple::Sub2
	    Simple
        |;
	given 'Simple' -> $module {
	    ok my $model = Agrammon::Model.new(path => $path);
	    $model.load($module);
	    is $model.evaluation-order.elems, @expected.elems,
	        "Loaded {@expected.elems} model files";
	    my @tax;
	    for $model.evaluation-order { @tax.push($_.taxonomy) };
	    is-deeply @tax, @expected, 'Load order as expected';
	}
    }

    subtest 'circular model detection' => {
	my $path = $*PROGRAM.parent.add('test-data/Models/test_circular/');
	given 'Circular' -> $module {
	    ok my $model = Agrammon::Model.new(path => $path);
	    throws-like { $model.load($module) },
	                  X::Agrammon::Model::CircularModel,
 			  "Circular model $module";
	}
	given 'Simple' -> $module {
	    ok my $model = Agrammon::Model.new(path => $path);
	    throws-like { $model.load($module) },
	                  X::Agrammon::Model::CircularModel,
 			  "Circular model $module";
	}
    }

    subtest 'hr-inclNOx model partial loading' => {

	diag "Testing hr-inclNOx";
	my $path = $*PROGRAM.parent.add('test-data/Models/hr-inclNOx/');
	my @expected = qw|
            Livestock::DairyCow::Excretion::CMilk
	    Livestock::DairyCow::Excretion::CFeedSummerRatio
	    Livestock::DairyCow::Excretion::CFeedWinterRatio
	    Livestock::DairyCow::Excretion::CConcentrates
	    Livestock::DairyCow::Excretion::CFeed
	    Livestock::DairyCow::Excretion
        |;
	given 'Livestock::DairyCow::Excretion' -> $module {
	    ok my $model = Agrammon::Model.new(path => $path);
	    $model.load($module);
	    is $model.evaluation-order.elems, 6, "Loaded 6 model file";
	    my @tax;
	    for $model.evaluation-order { @tax.push($_.taxonomy) };
	    is-deeply @tax, @expected,'Load order as expected';
	}
    }
    
}

done-testing;
