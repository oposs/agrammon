use lib %*ENV<HOME> ~ '/.agrammon';
use Agrammon::ModelCache;
use Agrammon::TechnicalParser;
use Agrammon::DataSource::CSV;

sub MAIN(Str :$dir = 'share/Models/version7.0.0', Str :$mod = 'End',
         Str :$input = 't/test-data/hr-inclNOxExtended-model-input.csv', Int :$n = 50) {
    my $cache = $*HOME.add('.agrammon');
    my $t0 = now;
    my $model = load-model-using-cache($cache, $dir.IO, $mod, set('Base'));
    my $load = now - $t0;
    my %tech = load-technical($dir.IO, 'technical.cfg');
    my @inputs = Agrammon::DataSource::CSV.new.read(open $input).list;
    my $in = @inputs[0];
    $in.apply-defaults($model, %tech);
    $model.run(:input($in), :technical(%tech));   # warm-up
    my $s0 = now;
    $model.run(:input($in), :technical(%tech)) for ^$n;
    my $sim = (now - $s0) / $n;
    say "LOAD_s=", $load.fmt('%.3f'), " SIM_ms=", ($sim*1000).fmt('%.3f'), " n=$n datasets=", @inputs.elems;
}
