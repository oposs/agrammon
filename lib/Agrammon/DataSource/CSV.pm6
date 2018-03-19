use v6;
use Agrammon::Inputs;
use Text::CSV;

class Agrammon::DataSource::CSV {
    method read($fh) {
        my $csv = Text::CSV.new(sep => ";");
        return gather {
            my $prev;
            my @group;
            while $csv.getline($fh) -> @row {
                $prev //= @row[1];
                if $prev && @row[1] ne $prev {
                    take self!group-input(@group);
                    @group = ();
                }
                push @group, @row;
                $prev = @row[1];
            }
            take self!group-input(@group) if @group;
        }
    }

    method !group-input(@group) {
        my $input = Agrammon::Inputs.new(simulation-name => @group[0][0], dataset-id => @group[0][1]);
        for @group {
            if .[2] ~~ /^ (<-[\[]>+) '[' (<-[\[]>+) ']' ['::' (.+)] $/ {
                $input.add-multi-input(~$0, ~$1, ~($2 // ''), .[3], maybe-numify(.[4]))
            }
            else {
                $input.add-single-input(.[2], .[3], maybe-numify(.[4]));
            }
        }
        return $input;
    }

    sub maybe-numify($value) {
        +$value // $value
    }
}
