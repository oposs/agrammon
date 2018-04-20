use v6;
use Agrammon::Model;
use Agrammon::ModelCache;
use Test;

plan 4;

subtest "Helper function" => {
    
    my $path = $*PROGRAM.parent.add('test-data/');
    given 'Livestock::DairyCow::Excretion::CMilk' -> $module-name {
	ok my $model = Agrammon::Model.new(path => $path);
        is $model.module2file($module-name),
            $path ~ 'Livestock/DairyCow/Excretion/CMilk.nhd',
            "module2file(): convert module $module-name to file";
    }

}


subtest "loadModule()" => {

    my $path = $*PROGRAM.parent.add('test-data/');
    given 'CMilk' -> $module-name {
        ok my $model = Agrammon::Model.new(path => $path);
        ok my $module = $model.load-module($module-name), "Load module $module-name";
        is $module.input[0].name, 'milk_yield', "Found input milk_yield";
    }

    given 'CMilk' -> $module-name {
        chmod 0, $path ~ $module-name ~ '.nhd';
        ok my $model = Agrammon::Model.new(path => $path);
        throws-like { $model.load-module($module-name) },
                      X::Agrammon::Model::FileNotReadable,
                      "Cannot load module $module-name from read-only file";
        chmod 0o644, $path ~ $module-name ~ '.nhd';
    }

    given 'CMilk_notExists' -> $module-name {
        ok my $model = Agrammon::Model.new(path => $path);
        throws-like { $model.load-module($module-name) },
                    X::Agrammon::Model::FileNotFound,
                    "Cannot load module $module-name from none-existing file";
    }

    $path = $*PROGRAM.parent.add('test-data/Models/hr-inclNOx/');
    given 'Livestock' -> $module-name {
        ok my $model = Agrammon::Model.new(path => $path);
        my $module = $model.load-module($module-name);
        is $module.parent, '', "Module $module-name has no parent";
        is $module.name, $module-name, "Module $module-name has name $module-name";
    }

    given 'Livestock::DairyCow::Excretion::CMilk' -> $module-name {
        ok my $model = Agrammon::Model.new(path => $path);
        my $module = $model.load-module($module-name);
        is $module.parent,
            'Livestock::DairyCow::Excretion',
            "Module $module-name has parent Livestock::DairyCow::Excretion";
        is $module.name, 'CMilk', "Module $module-name has name CMilk";
    }

}


subtest 'load()' => { 

    subtest 'Simple model loading' => {
        my $path = $*PROGRAM.parent.add('test-data/Models/test_simple/');
        my @expected = qw|
            Simple::Sub1a
            Simple::Sub1
            Simple::Sub2a
            Simple::Sub2b
            Simple::Sub2
            Simple
        |;
        given 'Simple' -> $module-name {
            ok my $model = Agrammon::Model.new(path => $path);
            $model.load($module-name);
            is $model.evaluation-order.elems, @expected.elems,
                "Loaded {@expected.elems} model files";
            my @tax = $model.evaluation-order>>.taxonomy;
            is-deeply @tax, @expected, 'Load order as expected';
        }
    }

    subtest 'circular model detection' => {
        my $path = $*PROGRAM.parent.add('test-data/Models/test_circular/');
        given 'Circular' -> $module-name {
            ok my $model = Agrammon::Model.new(path => $path);
            throws-like { $model.load($module-name) },
                          X::Agrammon::Model::CircularModel,
                          "Circular model $module-name";
        }
        given 'Simple' -> $module-name {
            ok my $model = Agrammon::Model.new(path => $path);
            throws-like { $model.load($module-name) },
                          X::Agrammon::Model::CircularModel,
                          "Circular model $module-name";
        }
    }

    subtest 'hr-inclNOx model partial loading' => {
        diag "Testing hr-inclNOx partial";
        my $path = $*PROGRAM.parent.add('test-data/Models/hr-inclNOx/');
        my @expected = qw|
            Livestock::DairyCow::Excretion::CMilk
            Livestock::DairyCow::Excretion::CFeedSummerRatio
            Livestock::DairyCow::Excretion::CFeedWinterRatio
            Livestock::DairyCow::Excretion::CConcentrates
            Livestock::DairyCow::Excretion::CFeed
            Livestock::DairyCow::Excretion
        |;
        given 'Livestock::DairyCow::Excretion' -> $module-name {
            ok my $model = Agrammon::Model.new(path => $path);
            $model.load($module-name);
            is $model.evaluation-order.elems, 6, "Loaded 6 model file";
            my @tax = $model.evaluation-order>>.taxonomy;
            is-deeply @tax, @expected,'Load order as expected';
        }
    }
    
    subtest 'hr-inclNOx model full loading' => {
        diag "Testing hr-inclNOx full";
        my $path = $*PROGRAM.parent.add('test-data/Models/hr-inclNOx/');
        my @expected = qw|
            Livestock::DairyCow::Excretion::CMilk
            Livestock::DairyCow::Excretion::CFeedSummerRatio
            Livestock::DairyCow::Excretion::CFeedWinterRatio
            Livestock::DairyCow::Excretion::CConcentrates
            Livestock::DairyCow::Excretion::CFeed
            Livestock::DairyCow::Excretion
            Livestock::DairyCow::Housing::Type::Tied_Housing_Slurry
            Livestock::DairyCow::Housing::Type::Tied_Housing_Slurry_Plus_Solid_Manure
            Livestock::DairyCow::Housing::Type::Loose_Housing_Slurry
            Livestock::DairyCow::Housing::Type::Loose_Housing_Slurry_Plus_Solid_Manure
            Livestock::DairyCow::Housing::Type::Loose_Housing_Deep_Litter
            Livestock::DairyCow::Housing::Type
            Livestock::DairyCow::Housing::Floor
            Livestock::DairyCow::Housing::ClimateAir
            Livestock::DairyCow::Housing::CFreeFactor
            Livestock::DairyCow::GrazingInput
            Livestock::DairyCow::Yard
            Livestock::DairyCow::Grazing
            Livestock::DairyCow::Housing::KGrazing
            Livestock::DairyCow::Housing
            Livestock::DairyCow
            Livestock::OtherCattle::Excretion
            Livestock::OtherCattle::Housing::Type::Tied_Housing_Slurry
            Livestock::OtherCattle::Housing::Type::Tied_Housing_Slurry_Plus_Solid_Manure
            Livestock::OtherCattle::Housing::Type::Loose_Housing_Slurry
            Livestock::OtherCattle::Housing::Type::Loose_Housing_Slurry_Plus_Solid_Manure
            Livestock::OtherCattle::Housing::Type::Loose_Housing_Deep_Litter
            Livestock::OtherCattle::Housing::Type
            Livestock::OtherCattle::Housing::Floor
            Livestock::OtherCattle::Housing::ClimateAir
            Livestock::OtherCattle::Housing::CFreeFactor
            Livestock::OtherCattle::GrazingInput
            Livestock::OtherCattle::Yard
            Livestock::OtherCattle::Grazing
            Livestock::OtherCattle::Housing::KGrazing
            Livestock::OtherCattle::Housing
            Livestock::OtherCattle
            Livestock::Pig::Excretion
            Livestock::Pig::Housing::Type::Slurry_Conventional
            Livestock::Pig::Housing::Type::Slurry_Label
            Livestock::Pig::Housing::Type::Slurry_Label_Open
            Livestock::Pig::Housing::Type::Deep_Litter
            Livestock::Pig::Housing::Type::Outdoor
            Livestock::Pig::Housing::Type
            Livestock::Pig::Grazing
            Livestock::Pig::Housing::AirScrubber
            Livestock::Pig::Housing::MitigationOptions
            Livestock::Pig::Housing::CFreeFactor
            Livestock::Pig::Housing
            Livestock::Pig
            Livestock::FatteningPigs::Excretion
            Livestock::FatteningPigs::Housing::Type::Slurry_Conventional
            Livestock::FatteningPigs::Housing::Type::Slurry_Label
            Livestock::FatteningPigs::Housing::Type::Slurry_Label_Open
            Livestock::FatteningPigs::Housing::Type::Deep_Litter
            Livestock::FatteningPigs::Housing::Type::Outdoor
            Livestock::FatteningPigs::Housing::Type
            Livestock::FatteningPigs::Grazing
            Livestock::FatteningPigs::Housing::AirScrubber
            Livestock::FatteningPigs::Housing::MitigationOptions
            Livestock::FatteningPigs::Housing::CFreeFactor
            Livestock::FatteningPigs::Housing
            Livestock::FatteningPigs
            Livestock::Poultry::Excretion
            Livestock::Poultry::Outdoor
            Livestock::Poultry::Housing::Type
            Livestock::Poultry::Housing::AirScrubber
            Livestock::Poultry::Housing::CFreeFactor
            Livestock::Poultry::Housing
            Livestock::Poultry
            Livestock::Equides::Excretion
            Livestock::Equides::Grazing
            Livestock::Equides::Housing::KGrazing
            Livestock::Equides::Yard
            Livestock::Equides::Housing
            Livestock::Equides
            Livestock::SmallRuminants::Excretion
            Livestock::SmallRuminants::Grazing
            Livestock::SmallRuminants::Housing::KGrazing
            Livestock::SmallRuminants::Housing
            Livestock::SmallRuminants
            Livestock::RoughageConsuming::Excretion
            Livestock::RoughageConsuming::Grazing
            Livestock::RoughageConsuming::Housing::KGrazing
            Livestock::RoughageConsuming::Housing
            Livestock::RoughageConsuming
            Livestock
            Storage::SolidManure::Poultry
            Storage::SolidManure::Solid
            Storage::SolidManure
            Storage::Slurry::EFLiquid
            Storage::Slurry
            Storage
            Application::Slurry::Ctech
            Application::Slurry::Applrate
            Application::Slurry::Csoft
            Application::Slurry::Cseason
            Application::Slurry::Cfermented
            Application::Slurry::CfreeFactor
            Application::Slurry
            Application::SolidManure::CincorpTime
            Application::SolidManure::Solid::CincorpTime
            Application::SolidManure::Cseason
            Application::SolidManure::CfreeFactor
            Application::SolidManure::Solid
            Application::SolidManure::Poultry::CincorpTime
            Application::SolidManure::Poultry
            Application::SolidManure
            Application
            SummaryByAnimalCategory
            PlantProduction::AgriculturalArea
            PlantProduction::MineralFertiliser
            PlantProduction::RecyclingFertiliser
            PlantProduction
            Total
            SharesByAnimalCategory
            End
        |;
        given 'End' -> $module-name {
            ok my $model = Agrammon::Model.new(path => $path);
            $model.load($module-name);
            is $model.evaluation-order.elems, @expected.elems,
                "Loaded @expected.elems() model file";
            my @tax = $model.evaluation-order>>.taxonomy;
            is-deeply @tax, @expected, 'Load order as expected';
        }
    }
}

subtest 'dump()' => {
    my $path = $*PROGRAM.parent.add('test-data/Models/test_simple/');
    my $output-expected = q:to/OUTPUT/;
        Simple
        Simple::Sub2
        Simple::Sub2b
        Simple::Sub2a
        Simple::Sub1
        Simple::Sub1a
        OUTPUT
    given 'Simple' -> $module {
        ok my $model = Agrammon::Model.new(path => $path);
        $model.load($module);
        is $model.dump, $output-expected, 'Output as expected';
    }
}

done-testing;
