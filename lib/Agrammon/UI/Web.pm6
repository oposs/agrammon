use v6;
use Agrammon::Model;

class Agrammon::UI::Web {
    has Agrammon::Model $.model;

    method !get-inputs {
        my @inputs;
        for $!model.load-order -> $module {
            # we want the inputs shown in the GUI in load order as well
            my $order = 100;
            my $order-increment = 100;
            for $module.input -> $input {
                $order += $order-increment;
                my %input-hash = $input.as-hash;
                %input-hash<order> = $order;
                my $gui= $module.gui || $module.gui-root-module.gui;
                my @gui = split(',', $gui);
                if $module.instance-root {
                    # append [] to each element in the array
                    @gui >>~=>> '[]';
                }
                %input-hash<gui>      = %( <en de fr> Z=> @gui );
                %input-hash<branch>   = $module.is-multi ?? 'true' !! 'false';
                my $tax               = $module.taxonomy;

                my $root = $module.instance-root;
                if $root {
                    $tax ~~ s/$root/$root\[\]/;
                }
                %input-hash<variable> = $tax ~ '::' ~ %input-hash<variable>;
                push @inputs, %input-hash;
            }
        }
        return @inputs;
    }

    method !get-results {
        my (@reports, @graphs);

        for $!model.evaluation-order -> $module {
            for $module.results -> $result {
                my %result-hash = $result.as-hash;

                my $type = $result.type;
                my %report =
                    :name($result.name),
                    :order($result.order),
                    :selector($result.selector),
                    :$type,
                    :submit($result.is-submit),
                    :resultView($result.is-result-view);

                my @data;
                my @report-data = %result-hash<data>;
                for @report-data -> @sub-reports {
                    for @sub-reports -> $sub-report {
                        for $sub-report.kv -> $print, %langLabels {
                            my %opts = %( :%langLabels, :$print, );
                            push @data, %opts;
                        }
                    }
                    %report<data> = @data;
                    given $type {
                        when 'report' | 'reportDetailed' { push @reports, %report }
                        when 'bar'    | 'pie'            { push @graphs, %report }
                        default { die "Unknown report type $type" }
                    }
                }
            }
        }
        return %( :@reports, :@graphs, );
    }

    method get-input-variables {
        return %( self!get-results, inputs => self!get-inputs );
    }

}
