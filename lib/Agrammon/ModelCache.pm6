use Agrammon::Formula::Compiler;
use Agrammon::Model;
use Digest::SHA1::Native;

sub load-model-using-cache(IO() $cache-dir, IO() $path, $module) is export {
    my $hash = hash-path($path).trans('0'..'9' => 'A'..'J');
    my $cached = $cache-dir.IO.add("$hash.pm6");
    unless $cached.e {
        my $m = Agrammon::Model.new(path => $path, :!compile-formulas);
        $m.load($module);
        mkdir $cache-dir;
        spurt $cached, q:c:to/MODULE/;
            unit module {$hash};
            use Agrammon::Model;
            our $model = BEGIN Agrammon::Model
                    .new(path => {$path.absolute.perl}.IO)
                    .load({$module.perl}, :!compile-formulas);
            my @modules := $model.evaluation-order;
            {set-formulas-code($m)}
            MODULE
    }
    use MONKEY-SEE-NO-EVAL;
    return EVAL "use lib '$cache-dir.absolute()'; use $hash; {$hash}::<\$model>";
}

sub hash-path($base) {
    my %path-hashes;
    react {
        sub hash-file($path) {
            whenever start { sha1-hex slurp $path, :bin } -> $hash {
                %path-hashes{$path} = $hash;
            }
        }

        sub walk($dir) {
            whenever start eager $dir.dir -> @files {
                for @files {
                    when .f && /'.nhd'$/ { hash-file($_) }
                    when .d { walk($_) }
                }
            }
        }

        walk($base);
    }
    return sha1-hex %path-hashes.sort(*.key).map({ "{.key}\0{.value}\0" }).join;
}

sub set-formulas-code(Agrammon::Model $model) {
    my @formula-set-lines;
    for $model.evaluation-order.kv -> $midx, $module {
        for $module.output.kv -> $oidx, $output {
            my $source = compile-formula-to-source($output.formula);
            push @formula-set-lines, q:c'@modules[{$midx}].output[{$oidx}].compiled-formula = {$source}';
        }
    }
    return @formula-set-lines.join("\n");
}
