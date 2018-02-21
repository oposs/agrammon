use v6;
use Agrammon::Model::Input;
use Agrammon::Model::Module;
use Agrammon::Model::Output;
use Agrammon::Model::Test;
use Agrammon::Model::Technical;

class Agrammon::ModelBuilder {
    method TOP($/) {
        make Agrammon::Model::Module.new(|flat($<section>.map(*.ast)).Map);
    }

    method section:sym<general>($/) {
        make %( $<option>.map(*.ast) );
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

    method section:sym<output>($/) {
        make 'output' => $<output>.map({
            Agrammon::Model::Output.new(|.ast)
        });
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
        make ~$<key> => %( $<value>.map(*.ast) );
    }

    method single-line-option($/) {
        make ~$<key> => ~$<value>;
    }

    method multi-line-str-option($/) {
        make ~$<key> => quietly $<value>.Str.indent(-$*indent).trim-trailing;
    }
}
