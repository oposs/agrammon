use Agrammon::Formula::ControlFlow;
use Agrammon::Outputs;

sub get-builtins is export {
    return INIT %(
        writeLog => -> %langMessages {
            with $*AGRAMMON-LOG {
                .add-to-log(%langMessages);
            }
        },
        die => -> *@message {
            die X::Agrammon::Formula::Died.new(message => @message.join || 'Died');
        },
        warn => -> *@message {
            warn @message.join || 'Warning';
        },
        abs => &abs,
        # Construct a filter group from data
        filterGroup => &filter-group,
        # Turn a filter group into a simple scalar value
        scalar => &filter-group-scalar,
        # Scale all values in a filter group by the given multiplier
        scale => -> $filter-group, $multiplier {
            die "scale operator expects a filter group as its first argument"
                    unless $filter-group ~~ Agrammon::Outputs::FilterGroupCollection;
            $filter-group.scale(+$multiplier)
        },
        add => -> $filter-group, $additor {
            die "scale operator expects a filter group as its first argument"
                    unless $filter-group ~~ Agrammon::Outputs::FilterGroupCollection;
            $filter-group.add(+$additor)
        },        
        # P+ compiles into this
        addPairwise => -> $a, $b {
            my $ag = as-filter-group($a);
            my $bg = as-filter-group($b);
            $ag.apply-pairwise($b, &[+], 0)
        },
        # P- compiles into this
        subtractPairwise => -> $a, $b {
            my $ag = as-filter-group($a);
            my $bg = as-filter-group($b);
            $ag.apply-pairwise($b, &[-], 0)
        },
        # P/ compiles into this
        dividePairwise => -> $a, $b {
            my $ag = as-filter-group($a);
            my $bg = as-filter-group($b);
            $ag.apply-pairwise($b, &[/], 1)
        },
        # P* compiles into this
        multiplyPairwise => -> $a, $b {
            my $ag = as-filter-group($a);
            my $bg = as-filter-group($b);
            $ag.apply-pairwise($b, &[*], 0)
        },
    )
}

sub filter-group(Str $taxonomy, **@mappings) {
    unless @mappings %% 2 {
        die "filterGroup must receive a taxonomy followed by alternating filter group key and value parameters";
    }
    Agrammon::Outputs::FilterGroupCollection.from-filter-to-value-pairs: @mappings.map:
            -> $filter-source, $value {
                unless $filter-source ~~ Hash {
                    die "filterGroup filter values must be a hash";
                }
                my %filter;
                for $filter-source.kv -> $input, $filter-value {
                    %filter{$taxonomy ~ '::' ~ $input} = $filter-value;
                }
                %filter => $value
            }
}

multi as-filter-group(Agrammon::Outputs::FilterGroupCollection $group) {
    $group
}
multi as-filter-group(Any $value) {
    Agrammon::Outputs::FilterGroupCollection.from-scalar($value)
}

multi filter-group-scalar(Agrammon::Outputs::FilterGroupCollection $group) {
    $group.Numeric
}
multi filter-group-scalar(Any $value) {
    $value
}
