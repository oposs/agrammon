use v6;
use Agrammon::Formula::Parser;
use Agrammon::Model::External;
use Agrammon::Model::Input;
use Agrammon::Model::Module;
use Agrammon::Model::Output;
use Agrammon::Model::Test;
use Agrammon::Model::Technical;

class Agrammon::ModuleBuilder {
    has $!module-load-order = 0;

    my constant ORDERED = {
        input   => { :enum },
        results => { :data }
    }

    method TOP($/) {
        make Agrammon::Model::Module.new(|flat($<section>.map(*.ast)).Map, :load-order($!module-load-order++));
    }

    method section:sym<general>($/) {
        my %general := %( $<option>.map(*.ast) );
        with %general<taxonomy> {
            $*TAXONOMY = $_;
        }
        make %general;
    }

    method section:sym<external>($/) {
        make 'external' => $<external>.map({
            Agrammon::Model::External.new(|.ast)
        });
    }

    method section:sym<input>($/) {
        make 'input' => $<input>.map({
            Agrammon::Model::Input.new(|.ast)
        });
    }

    method section:sym<technical>($/) {
        make 'technical' => $<technical>.map({
            Agrammon::Model::Technical.new(|.ast)
        });
    }

    method section:sym<results>($/) {
        make 'results' => $<results>.map({
            Agrammon::Model::Result.new(|.ast)
        });
    }

    method section:sym<output>($/) {
        make 'output' => [$<output>.map(sub ($_) {
            my %output-props = .ast;
            with %output-props<formula> <-> $formula {
                %output-props<code> = $formula;
                with $*TAXONOMY -> $taxonomy {
                    $formula = parse-formula($formula, $taxonomy);
                    CATCH {
                        default {
                            die "Error compiling formula for output '%output-props<name>' " ~
                                "in $taxonomy: $_";
                        }
                    }
                }
                else {
                    die "Missing taxonomy in general section, or general section too late";
                }
            }
            Agrammon::Model::Output.new(|%output-props)
        })];
    }

    method section:sym<tests>($/) {
        make 'tests' => $<tests>.map({
            Agrammon::Model::Test.new(|.ast)
        });
    }

    method option-section($/) {
        make %(
            name => ~$<name>,
            |flat($<option>.map(*.ast)).Map
        );
    }

    method subsection-map($/) {
        my $key = ~$<key>;
        make $key => ORDERED{$*CUR-SECTION}{$key}
                ?? @( $<value>.map(*.ast) )
                !! %( $<value>.map(*.ast) );
    }

    method single-line-option($/) {
        make ~$<key> => ~$<value>;
    }

    method multi-line-str-option($/) {
        make ~$<key> => dedent($<value>.Str).trim-trailing;
    }

    #| Dedent a multi-line value going by the amount of indentation on the
    #| first non-empty line.
    sub dedent(Str $text) {
        $text ~~ /^\n*(\h+)/
            ?? quietly $text.indent(-$0.chars)
            !! $text
    }
}
