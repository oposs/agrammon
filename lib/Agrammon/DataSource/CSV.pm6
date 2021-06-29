use v6;
use Agrammon::Inputs;
use Agrammon::DataSource::Util;

class Agrammon::DataSource::CSV {
    method read($fh) {
        return gather {
            my $prev;
            my @group;
            my @outstanding;
            for $fh.lines.map(*.split(';')) -> @row {
                if $prev && @row[1] ne $prev {
                    push @outstanding, self!group-input(@group);
                    await @outstanding[0] if @outstanding >= 8;
                    while @outstanding[0] {
                        take @outstanding.shift.result;
                    }
                    @group := [];
                }
                push @group, @row;
                $prev = @row[1];
            }
            push @outstanding, self!group-input(@group) if @group;
            take .result for @outstanding;
        }
    }

    method !group-input(@group) {
        start {
            my $input = Agrammon::Inputs.new(simulation-name => @group[0][0], dataset-id => @group[0][1]);
            for @group {
                my $full-tax = .[2];
                if $full-tax.index('[') -> $sub-start {
                    my $tax = $full-tax.substr(0, $sub-start);
                    my $sub-end = $full-tax.index(']');
                    my $instance = $full-tax.substr($sub-start + 1, ($sub-end - $sub-start) - 1);
                    my $sub-tax = $full-tax.substr($sub-end + 1);
                    $input.add-multi-input($tax, $instance, $sub-tax ?? $sub-tax.substr(2) !! '', .[3], maybe-numify(.[4]))
                }
                else {
                    $input.add-single-input(.[2], .[3], maybe-numify(.[4]));
                }
            }
            $input
        }
    }

    method load($simulation-name, $dataset-id, $csv-data) {
        my $input = Agrammon::Inputs.new(:$simulation-name, :$dataset-id);
        for $csv-data.split("\n").map(*.split(';')) {
            next unless .[0];
            next if .[0] ~~ /^ '#' /;
            my $full-tax = .[0];
            if $full-tax.index('[') -> $sub-start {
                my $tax = $full-tax.substr(0, $sub-start);
                my $sub-end = $full-tax.index(']');
                my $instance = $full-tax.substr($sub-start + 1, ($sub-end - $sub-start) - 1);
                my $sub-tax = $full-tax.substr($sub-end + 1);
                $input.add-multi-input($tax, $instance, $sub-tax ?? $sub-tax.substr(2) !! '', .[1], maybe-numify(.[2]))
            }
            else {
                $input.add-single-input(.[0], .[1], maybe-numify(.[2]));
            }
        }
        return $input;
    }
}

# CSV input expected
# 2010v2.1_20120425;2648;Storage::SolidManure::Poultry;share_applied_direct_poultry_manure;20
# 2010v2.1_20120425;2648;Storage::SolidManure::Poultry;share_covered_basin;20
# 2010v2.1_20120425;2648;Livestock::Equides[HorsesUp3yr]::Excretion;animalcategory;horses_older_than_3yr
# 2010v2.1_20120425;2648;Livestock::Equides[HorsesUp3yr]::Excretion;animals;5
# 2010v2.1_20120425;2648;Livestock::Equides[HorsesUp3yr]::Outdoor;grazing_days;165
# 2010v2.1_20120425;2648;Livestock::Equides[HorsesUp3yr]::Outdoor;grazing_hours;0
# 2010v2.1_20120425;2648;Livestock::Equides[HorsesUp3yr]::Outdoor;floor_properties_exercise_yard;paddock_or_pasture_used_as_exercise_yard
# 2010v2.1_20120425;2648;Livestock::Equides[HorsesUp3yr]::Housing::CFreeFactor;free_correction_factor;5
# 2010v2.1_20120425;2648;Livestock::Equides[HorsesUp3yr]::Outdoor;yard_days;115
# 2010v2.1_20120425;2648;Livestock::Equides[HorsesUp3yr]::Outdoor;yard_hours;0
