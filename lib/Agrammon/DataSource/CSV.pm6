use v6;
use Agrammon::Inputs;

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

    sub maybe-numify($value) {
        +$value // $value
    }
}
