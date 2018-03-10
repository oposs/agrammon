use v6;
use Agrammon::Config;
use Agrammon::DB::Dataset;
use Agrammon::DB::Datasets;
use Agrammon::DB::User;
use Agrammon::DB::Tags;
use Agrammon::Web::UserSession;

class Agrammon::Web::Service {
    has Agrammon::Config   $.cfg;

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
    method get-datasets(Agrammon::Web::UserSession $user, Str $version) {
        return Agrammon::DB::Datasets.new(:$user, :$version).load.list;
    }

    method get-tags(Agrammon::Web::UserSession $user) {
        return Agrammon::DB::Tags.new(:$user).load.list;
    }

    method load-dataset(Agrammon::Web::UserSession $user, Str $name) {
        return Agrammon::DB::Dataset.new(:$user, :$name).load.data;
    }

    method create-dataset(Agrammon::Web::UserSession $user, Str $name) {
        return Agrammon::DB::Dataset.new(:$user, :$name).create;
    }

    method create-tag(Agrammon::Web::UserSession $user, Str $name) {
        return Agrammon::DB::Tag.new(:$user, :$name).create;
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
