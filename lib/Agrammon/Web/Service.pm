use v6;
use Agrammon::Config;
use Agrammon::DB::Dataset;
use Agrammon::DB::Datasets;
use Agrammon::DB::User;
use Agrammon::DB::Tags;

class Agrammon::Web::Service {
    has Agrammon::Config   $.cfg;
    has Agrammon::DB::User $.user;

    method get-cfg() {
        return $!cfg;
    }

    method get-datasets(Str $model-version) {
        my $datasets = Agrammon::DB::Datasets.new(user => $!user);
        $datasets.load($model-version, $!cfg);
        return $datasets;
    }

    method load-dataset(Str $dataset-name) {
        return Agrammon::DB::Dataset.new($!user).load($dataset-name, $!cfg).data;
    }

    method create-dataset(Str $dataset-name) {
        return Agrammon::DB::Dataset.new($!user).create($dataset-name);
    }

    method get-tags() {
        return Agrammon::DB::Tags.new($!user).collection;
    }

    method get-input-variables(Agrammon::DB::Dataset $dataset) {
    }

    method get-output-variables(Agrammon::DB::Dataset $dataset) {
    }

    method create-account(%user-data) {
        return Agrammon::DB::User.new(%user-data).create-account;
    }

}
