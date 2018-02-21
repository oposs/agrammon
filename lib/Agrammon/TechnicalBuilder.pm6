use v6;
use Agrammon::Model::Parameters;
use Agrammon::Model::Technical;

class Agrammon::TechnicalBuilder {
    method TOP($/) {
        make Agrammon::Model::Parameters.new(technical => $<parameters>.map(*.ast));
    }

    method option-section($/) {
         make %( $<name> => $<option>.map(*.ast));
    }

    method single-line-option($/) {
        make Agrammon::Model::Technical.new( name => ~$<key>, value => ~$<value> );
    }

}
