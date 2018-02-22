use v6;
use Text::CSV;

class Agrammon::DataSource::CSV {
    
    method read($fh) {

        my $csv = Text::CSV.new(sep => ";");
        return lazy gather {
            my $prev;
            my @group;
            while $csv.getline($fh) -> @row {
                $prev //= @row[1];
                if $prev && @row[1] ne $prev {
                    take @group;
                    @group = ();
                }
                push @group, @row;
                $prev = @row[1];
            }
            take @group if @group;
        }
    }

}
