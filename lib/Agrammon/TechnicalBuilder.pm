use v6;
use Agrammon::Model::Parameters;
use Agrammon::Model::Technical;

class Agrammon::TechnicalBuilder {
    method TOP($/) {
        make Agrammon::Model::Parameters.new(|flat($<section>.map(*.ast)).Map);
    }

    method section:sym<technical_parameters>($/) {
        make 'technical_parameters' => $<technical_parameters>.map({
            Agrammon::Model::Technical.new(|.ast)
        });
    }

    method option-section($/) {
        make %(
            name => ~$<name>,
            |flat($<option>.map(*.ast)).Map
        );
    }

    method single-line-option($/) {
        make ~$<key> => ~$<value>;
    }

}
