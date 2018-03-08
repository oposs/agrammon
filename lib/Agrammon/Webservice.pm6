use v6;
use Agrammon::Config;
use Agrammon::Dataset;
use Agrammon::Datasets;
use Agrammon::User;
use Agrammon::Tags;

class Agrammon::Webservice {
    has Agrammon::Config $.cfg;
    has Agrammon::User   $.user;

    method get-cfg() {
        return $!cfg;
    }

    method get-datasets(Str $model-version) {
        my $datasets = Agrammon::Datasets.new(user => $!user);
        $datasets.load($model-version);
        return $datasets;
    }

    method load-dataset(Str $dataset-name) {
        return Agrammon::Dataset.new($!user).load($dataset-name).data;
    }

    method create-dataset(Str $dataset-name) {
        return Agrammon::Dataset.new($!user).create($dataset-name);
    }

    method get-tags() {
        return Agrammon::Tags.new($!user);
    }

    method get-input-variables(Agrammon::Dataset $dataset) {
    }

    method get-output-variables(Agrammon::Dataset $dataset) {
    }

    method create-account(%user-data) {
        return Agrammon::User.new(%user-data).create-account;
    }

}
