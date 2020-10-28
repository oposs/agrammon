use v6;
use Agrammon::Model;

class Agrammon::UI::Web {
    has Agrammon::Model $.model;

    method !get-inputs {
        my @inputs;
        for $!model.evaluation-order -> $module {
            my @module-inputs;
            for $module.input -> $input {

                my %input-hash = $input.as-hash;
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
            my @module-inputs;
            for $module.results -> $result {
                my $type = $result.type;
                my %report = %(
                    name     => $result.name,
                    _order   => $result._order,
                    selector => $result.selector,
                    :$type,
                );

                my %data = $result.data;
                my @data;
                for %data.kv -> $key, $langLabels {
                    my %opts = %(
                        label      => $key,
                        subReports => split('_', $key),
                    );

                    my @langLabel  = split("\n", $langLabels);
                    for @langLabel -> $ll {
                        my ($lang, $label) = split(/ \s* '=' \s* /, $ll);
                        %opts{$lang} = $label;
                    }
                    push @data, %opts;
                }

                %report<data> = @data;

                given $type {
                    when 'report'      { push @reports, %report }
                    when 'bar' | 'pie' { push @graphs,  %report }
                    default            { die "Unknown report type $type" }
                }
            }
        }

        return %(
            :@reports,
            :@graphs,
        );
    }

    method get-input-variables {
        my %results = self!get-results;

        return %( %results, inputs => self!get-inputs );
    }

}
