use v6;
use Agrammon::Formula::Compiler;
use Agrammon::Model;
use Digest::SHA1::Native;

sub load-model-using-cache(IO() $cache-dir, IO() $path, $module, %preprocessor-options?) is export {
    my $hash = hash-model($path, %preprocessor-options).trans('0'..'9' => 'A'..'J');
    my $cached = $cache-dir.IO.add("$hash.pm6");
    unless $cached.e {
        my $m = Agrammon::Model.new(:$path, :%preprocessor-options, :!compile-formulas);
        $m.load($module);
        mkdir $cache-dir;
        spurt $cached, q:c:to/MODULE/;
            unit module {$hash};
            use Agrammon::Model;
            our $model = BEGIN Agrammon::Model
                    .new(path => {$path.absolute.perl}.IO, preprocessor-options => {%preprocessor-options.raku})
                    .load({$module.perl}, :!compile-formulas);
            my @modules := $model.evaluation-order;
            {set-formulas-code($m)}
            MODULE
    }
    use MONKEY-SEE-NO-EVAL;
    return EVAL "use lib '$cache-dir.absolute()'; use $hash; {$hash}::<\$model>";
}

sub hash-model($base, %preprocessor-options) {
    # Hash all of the model files; we'll form a composite hash from them.
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
    my $path-hashable = %path-hashes.sort(*.key).map({ "{ .key }\0{ .value }\0" }).join;

    # Also create a preprocessor hashable consisting of all the options.
    my $preproc-hashable = %preprocessor-options.grep(*.value).map(*.key).sort.join('\0');

    # Hash them together.
    return sha1-hex "$path-hashable\0$preproc-hashable";
}

sub set-formulas-code(Agrammon::Model $model) {
    my @formula-set-lines;
    for $model.evaluation-order.kv -> $midx, $module {
        for $module.input.kv -> $iidx, Agrammon::Model::Input $input {
            with $input.default-formula {
                my $source = compile-formula-to-source($_);
                push @formula-set-lines, q:c'@modules[{$midx}].input[{$iidx}].compiled-default-formula = {$source}';
            }
        }
        for $module.output.kv -> $oidx, $output {
            my $source = compile-formula-to-source($output.formula);
            push @formula-set-lines, q:c'@modules[{$midx}].output[{$oidx}].compiled-formula = {$source}';
        }
    }
    return @formula-set-lines.join("\n");
}
