use v6;
use Agrammon::Config;
use Agrammon::DataSource::DB;
use Agrammon::DB::Dataset;
use Agrammon::DB::Datasets;
use Agrammon::DB::User;
use Agrammon::DB::Tags;
use Agrammon::Model;
use Agrammon::OutputsCache;
use Agrammon::OutputFormatter::GUI;
use Agrammon::Performance;
use Agrammon::Web::SessionUser;
use Agrammon::UI::Web;

class Agrammon::Web::Service {
    has Agrammon::Config $.cfg;
    has Agrammon::Model  $.model;
    has %.technical-parameters;
    has Agrammon::UI::Web $.ui-web .= new(:$!model);
    has Agrammon::OutputsCache $!outputs-cache .= new;

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

    method delete-datasets(Agrammon::Web::SessionUser $user, @datasets) {
        return Agrammon::DB::Datasets.new(:$user).delete(@datasets);
    }

    # return list of datasets as expected by Web GUI
    method send-datasets(Agrammon::Web::SessionUser $user, @datasets) {
        return @datasets.elems;
#        return Agrammon::DB::Datasets.new(:$user, :$version).load.list;
    }


    method load-dataset(Agrammon::Web::SessionUser $user, Str $name) {
        warn "***** load-dataset($name) not yet completely implemented (branching)";
        my @data = Agrammon::DB::Dataset.new(:$user, :$name).load.data;
        return @data;
    }

    method create-dataset(Agrammon::Web::SessionUser $user, Str $name) {
        my $model = self.cfg.model-variant; # model 'SingleSHL';
        my $version = '2.0-stage';
        return Agrammon::DB::Dataset.new(:$user, :$name, :$model, :$version).create;
    }

    method rename-dataset(Agrammon::Web::SessionUser $user, Str $old, Str $new) {
        return Agrammon::DB::Dataset.new(:$user, :name($old)).rename($new);
    }

    method submit-dataset(Agrammon::Web::SessionUser $user, Str $name, Str $mail) {
        return Agrammon::DB::Dataset.new(:$user, :$name).lookup.submit($mail);
    }

    method store-dataset-comment(Agrammon::Web::SessionUser $user, Str $name, Str $comment) {
        return Agrammon::DB::Dataset.new(:$user, :$name).store-comment($comment);
    }

    method get-tags(Agrammon::Web::SessionUser $user) {
        return Agrammon::DB::Tags.new(:$user).load.list;
    }

    method create-tag(Agrammon::Web::SessionUser $user, Str $name) {
        return Agrammon::DB::Tag.new(:$user, :$name).create;
    }

    method delete-tag(Agrammon::Web::SessionUser $user, Str $name) {
        return Agrammon::DB::Tag.new(:$user, :$name).delete;
    }

    method rename-tag(Agrammon::Web::SessionUser $user, Str $old, Str $new) {
        return Agrammon::DB::Tag.new(:$user, :name($old)).rename($new);
    }

    method set-tag(Agrammon::Web::SessionUser $user, Str $dataset-name, Str $tag-name) {
        return Agrammon::DB::Dataset.new(:$user, :name($dataset-name)).lookup.set-tag($tag-name);
    }

    method remove-tag(Agrammon::Web::SessionUser $user, Str $dataset-name, Str $tag-name) {
        return Agrammon::DB::Dataset.new(:$user, :name($dataset-name)).lookup.remove-tag($tag-name);
    }

    method get-input-variables {
        return $!ui-web.get-input-variables;
    }

    method get-output-variables(Agrammon::Web::SessionUser $user, Str $dataset-name) {
        my $outputs = $!outputs-cache.get-or-calculate: $user.username, $dataset-name, -> {
            my $input = Agrammon::DataSource::DB.new.read($user.username, $dataset-name,
                    $!model.distribution-map);
            timed "$dataset-name", {
                $!model.run:
                        :$input,
                        technical => %!technical-parameters;
            }
        }

        use Agrammon::OutputFormatter::Text;
        my $result = output-as-text($!model, $outputs, 'de', 'LivestockTotal');
        my %gui-output = output-for-gui($!model, $outputs);
        warn '**** get-output-variables() not yet completely implemented';
        return %gui-output;
    }

    method create-account(Agrammon::Web::SessionUser $user, $user-data) {
        return Agrammon::DB::User.new(|$user-data).create-account('user');
    }

    method change-password(Agrammon::Web::SessionUser $user, Str $old-password, Str $new-password) {
        return $user.change-password($old-password, $new-password);
    }

    method reset-password(Agrammon::Web::SessionUser $user, Str $email, Str $password, Str $key) {
        return $user.reset-password($email, $password, $key);
    }

    method store-data(Agrammon::Web::SessionUser $user, %data) {

        my $dataset = %data<dataset_name>;
        my $var     = %data<data_var>;
        my $value   = %data<data_val>;

        my $branches = %data<branches>;
        my $options  = %data<options>;

        my $ds = Agrammon::DB::Dataset.new(:$user, :name($dataset));

        my $ret = $ds.store-input($var, $value);

        $!outputs-cache.invalidate($user.username, $dataset);

        warn "**** store-data(var=$var, value=$value): not yet completely implemented (branch data)";
        return 1;
    }

    method store-input-comment(Agrammon::Web::SessionUser $user, Str $dataset-name, Str $var-name, Str $comment) {
        return Agrammon::DB::Dataset.new(:$user, :name($dataset-name)).lookup.store-input-comment($var-name, $comment);
    }

    method delete-data(Agrammon::Web::SessionUser $user, %data) {
        my $dataset-name = %data<dataset_name>;
        my $var-name     = %data<pattern>;
        return Agrammon::DB::Dataset.new(:$user, :name($dataset-name)).delete-input($var-name);
    }

    method load-branch-data(Agrammon::Web::SessionUser $user, Str $name) {
        return Agrammon::DB::Dataset.new(:$user, :$name).lookup.load-branch-data;
    }

    method store-branch-data(Agrammon::Web::SessionUser $user, Str $name, %data) {
        return Agrammon::DB::Dataset.new(:$user, :$name).store-branch-data(%data);
    }

    method rename-instance(Agrammon::Web::SessionUser $user, Str $dataset-name, Str $old-instance, Str $new-instance, Str $pattern) {
        return Agrammon::DB::Dataset.new(:$user, :name($dataset-name)).lookup.rename-instance($old-instance, $new-instance, $pattern);
    }

    method order-instances(Agrammon::Web::SessionUser $user, Str $dataset-name, @instances) {
        return Agrammon::DB::Dataset.new(:$user, :$dataset-name).lookup.order-instances(@instances);
    }

}
