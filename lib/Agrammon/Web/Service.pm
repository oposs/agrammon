use v6;
use Agrammon::Config;
use Agrammon::DB::Dataset;
use Agrammon::DB::Datasets;
use Agrammon::DB::User;
use Agrammon::DB::Tags;

class Agrammon::Web::Service {
    has Agrammon::Config   $.cfg;
    has Agrammon::DB::User $.user;

    # return config hash as expected by Web GUI
    method get-cfg() {
        my %gui   = $!cfg.gui;
        my %model = $!cfg.model;
        my %cfg = (
            guiVariant   => %gui<variant>,
            modelVariant => %model<variant>,
            title        => %gui<title>,
            variant      => %model<variant>,
            version      => %model<version>,
        );
        return %cfg;
    }

    # return list of datasets as expected by Web GUI
    method get-datasets(Str $model-version) {
        my $datasets = Agrammon::DB::Datasets.new(user => $!user);
        $datasets.load($model-version);
        return $datasets.list;
    }

    method load-dataset(Str $dataset-name) {
        return Agrammon::DB::Dataset.new($!user).load($dataset-name).data;
    }

    method create-dataset(Str $dataset-name) {
        my $dataset = Agrammon::DB::Dataset.new($!user);
        $dataset.create($dataset-name, $!cfg);
        return $dataset;
    }

    method get-tags() {
        my $tags = Agrammon::DB::Tags.new($!user);
        $tags.load($!cfg);
        return $tags;
    }

    method get-input-variables(Agrammon::DB::Dataset $dataset) {
        ...
    }

    method get-output-variables(Agrammon::DB::Dataset $dataset) {
        ...
    }

    method create-account(%user-data, Str $role) {
        my $user = Agrammon::DB::User.new(%user-data);
        $user.create-account($role);
        return $user;
    }

}
