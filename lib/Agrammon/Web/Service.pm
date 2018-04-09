use v6;
use Agrammon::Config;
use Agrammon::DB::Dataset;
use Agrammon::DB::Datasets;
use Agrammon::DB::User;
use Agrammon::DB::Tags;
use Agrammon::Model;
use Agrammon::Web::SessionUser;

class Agrammon::Web::Service {
    has Agrammon::Config $.cfg;
    has Agrammon::Model  $.model;

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
    method get-datasets(Agrammon::Web::SessionUser $user, Str $version) {
        return Agrammon::DB::Datasets.new(:$user, :$version).load.list;
    }

    method get-tags(Agrammon::Web::SessionUser $user) {
        return Agrammon::DB::Tags.new(:$user).load.list;
    }

    method load-dataset(Agrammon::Web::SessionUser $user, Str $name) {
        return Agrammon::DB::Dataset.new(:$user, :$name).load.data;
    }

    method create-dataset(Agrammon::Web::SessionUser $user, Str $name) {
        return Agrammon::DB::Dataset.new(:$user, :$name).create;
    }

    method create-tag(Agrammon::Web::SessionUser $user, Str $name) {
        return Agrammon::DB::Tag.new(:$user, :$name).create;
    }

    method get-input-variables(Agrammon::DB::Dataset $dataset) {
        return Agrammon::Model
    }

    method get-output-variables(Agrammon::DB::Dataset $dataset) {
        ...
    }

    method create-account(Agrammon::Web::SessionUser $user, %user-data) {
        my $newUser = Agrammon::DB::User.new(%user-data);
        $newUser.create;
        return $newUser;
    }

    method change-password(Agrammon::Web::SessionUser $user, Str $old, Str $new) {
        $user.change-password($old, $new);
        return $user;
    }

}
