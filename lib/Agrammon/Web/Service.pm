use v6;
use Agrammon::Config;
use Agrammon::DataSource::DB;
use Agrammon::DB::Dataset;
use Agrammon::DB::Datasets;
use Agrammon::DB::User;
use Agrammon::DB::Tags;
use Agrammon::Model;
use Agrammon::OutputFormatter::GUI;
use Agrammon::Performance;
use Agrammon::Web::SessionUser;
use Agrammon::UI::Web;

class Agrammon::Web::Service {
    has Agrammon::Config $.cfg;
    has Agrammon::Model  $.model;
    has %.technical-parameters;
    has Agrammon::UI::Web $.ui-web .= new(:$!model);

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
        warn "***** load-dataset($name) not yet completely implemented (branching)";
        my @data = Agrammon::DB::Dataset.new(:$user, :$name).load.data;
        return @data;
    }

    method create-dataset(Agrammon::Web::SessionUser $user, Str $name) {
        return Agrammon::DB::Dataset.new(:$user, :$name).create;
    }

    method create-tag(Agrammon::Web::SessionUser $user, Str $name) {
        return Agrammon::DB::Tag.new(:$user, :$name).create;
    }

    method get-input-variables {
        return $!ui-web.get-input-variables;
    }

    method get-output-variables(Agrammon::Web::SessionUser $user, Str $dataset-name) {

        my $input = Agrammon::DataSource::DB.new.read($user.username, $dataset-name);

        my $outputs;
        timed "$dataset-name", {
            $outputs = $!model.run(
                :$input,
                technical => %!technical-parameters,
            );
        }

        use Agrammon::OutputFormatter::Text;
        my $result = output-as-text($!model, $outputs, 'de', 'LivestockTotal');
        my %gui-output = output-for-gui($!model, $outputs);
        warn '**** get-output-variables() not yet completely implemented';
        return %gui-output;
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

    method store-data(Agrammon::Web::SessionUser $user, %data) {
        my $dataset = %data<dataset_name>;
        my $var     = %data<data_var>;
        my $value   = %data<data_val>;

        my $branches = %data<branches>;
        my $options  = %data<options>;

        my $ds = Agrammon::DB::Dataset.new(:$user, name => $dataset);

        my $ret = $ds.store-input($var, $value);

        warn "**** store-data(var=$var, value=$value): not yet completely implemented (branch data)";
        return 1;
    }

}
