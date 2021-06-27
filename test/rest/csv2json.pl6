use v6;

use JSON::Fast;

sub MAIN(Str $filename) {

    my @rows = $filename.IO.slurp.split("\n");

    my %inputs;

    my ($simulation, $run, $module, $var, $value);
    for @rows -> $row {
        next unless $row;
        ($simulation, $run, $module, $var, $value) = $row.split(';');
        if $module ~~ / $<root> = [ .+ ] '[' $<instance> = [ .+ ] ']' $<sub> = [ .* ] / {
            %inputs{~$<root> ~ '[]' ~ (~$<sub> // '')}{~$<instance>}{$var} = $value;
        }
        else {
            %inputs{$module}{$var} = $value;
        }
    }

    say to-json %inputs, :!pretty;
 }
