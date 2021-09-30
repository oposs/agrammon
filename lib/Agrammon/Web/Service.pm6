use v6;

use IO::Path::ChildSecure;

use Agrammon::Config;
use Agrammon::DataSource::DB;
use Agrammon::DataSource::CSV;
use Agrammon::DataSource::JSON;
use Agrammon::DB::Dataset;
use Agrammon::DB::Datasets;
use Agrammon::DB::User;
use Agrammon::DB::Tags;
use Agrammon::Documentation;
use Agrammon::Email;
use Agrammon::Model;
use Agrammon::ModelCache;
use Agrammon::OutputsCache;
use Agrammon::OutputFormatter::CSV;
use Agrammon::OutputFormatter::Excel;
use Agrammon::OutputFormatter::JSON;
use Agrammon::OutputFormatter::PDF;
use Agrammon::OutputFormatter::Text;
use Agrammon::Performance;
use Agrammon::TechnicalParser;
use Agrammon::Timestamp;
use Agrammon::UI::Web;
use Agrammon::Validation;
use Agrammon::Web::SessionUser;

class Agrammon::Web::Service {
    has Agrammon::Config $.cfg;
    has Agrammon::Model  $.model;
    has %.technical-parameters;
    has Agrammon::UI::Web $.ui-web .= new(:$!model);
    has Agrammon::OutputsCache $!outputs-cache .= new;

    #| return config hash as expected by Web GUI
    method get-cfg() {
        my %gui   = $!cfg.gui;
        my %model = $!cfg.model;
        my %cfg = (
            guiVariant   => %gui<variant>,
            modelVariant => %model<variant>,
            title        => %gui<title>,
            variant      => %model<variant>,
            version      => %model<version>,
            submission   => %gui<submission>,
        );
        return %cfg;
    }

    #| return list of datasets as expected by Web GUI
    method get-datasets(Agrammon::Web::SessionUser $user, $type) {
        return Agrammon::DB::Datasets.new(
            :$user, :agrammon-variant($!cfg.agrammon-variant)
        ).load.list;
    }

    method delete-datasets(Agrammon::Web::SessionUser $user, @datasets) {
        return Agrammon::DB::Datasets.new(:$user, :agrammon-variant($!cfg.agrammon-variant)).delete(@datasets);
    }

    #| return list of datasets as expected by Web GUI
    method send-datasets(Agrammon::Web::SessionUser $user, @datasets, $recipient, $language) {
        # prevent SPAMing
        die X::Agrammon::DB::User::UnknownUser.new(:username($recipient)) unless Agrammon::DB::User.new(:username($recipient)).exists;

        my %lx      = $!cfg.translations{$language};
        my $sent    = Agrammon::DB::Datasets.new(
            :$user, :agrammon-variant($!cfg.agrammon-variant)
        ).send(@datasets, $recipient)<sent>;

        # set in t/webservice.t to avoid sending email
        if not %*ENV<AGRAMMON_TESTING> {
            my $sender  = $user.username;
            my $subject = $sent == 1 ?? %lx{'new dataset'}[0]  !! %lx{'new dataset'}[1];
            my $format  = $sent == 1 ?? %lx{'dataset sent'}[0] !! %lx{'dataset sent'}[1];
            my $msg     = sprintf $format, @datasets.join(', '), $sender;
            Agrammon::Email.new(
                :to($recipient),
                :from('support@agrammon.ch'),
                :$subject,
                :$msg,
            ).send;
        }
        return %(:$sent);
    }

    method load-dataset(Agrammon::Web::SessionUser $user, Str $name) {
        my @data = Agrammon::DB::Dataset.new(
            :$user,
            :agrammon-variant($!cfg.agrammon-variant),
            :$name
        ).load.data;
        return @data;
    }

    method create-dataset(Agrammon::Web::SessionUser $user, Str $name) {
        return Agrammon::DB::Dataset.new(
            :$user,
            :agrammon-variant($!cfg.agrammon-variant),
            :$name
        ).create.name;
    }

    method clone-dataset(Agrammon::Web::SessionUser $user,
                         Str $new-username,
                         Str $old-dataset, Str $new-dataset --> Nil) {
        Agrammon::DB::Dataset.new(
            :$user,
            :agrammon-variant($!cfg.agrammon-variant)
        ).clone(:$new-username, :$old-dataset, :$new-dataset);
    }

    method rename-dataset(Agrammon::Web::SessionUser $user, Str $old, Str $new --> Nil) {
        Agrammon::DB::Dataset.new(
            :$user,
            :agrammon-variant($!cfg.agrammon-variant),
            :name($old)
        ).rename($new);
    }

    method submit-dataset(Agrammon::Web::SessionUser $user, %params) {
        my %lx = $!cfg.translations{%params<language> // 'de'};

        my $recipientKey = %params<recipientKey>;
        my $recipientMail;
        for @($!cfg.submission) -> %s {
            $recipientMail = %s<email> if %s<key> eq $recipientKey;
        }
        die "Recipient for key $recipientKey not found" unless $recipientMail;

        my $old-dataset  = %params<oldDataset>;
        my $new-dataset  = submission-dataset(%params);
        self.clone-dataset($user, $recipientMail, $old-dataset, $new-dataset);

        # set in t/webservice.t to avoid sending email
        if not %*ENV<AGRAMMON_TESTING> {
            my $attachment = self.get-pdf-export($user, %params);
            my $subject = %lx<dataset> ~ ": $new-dataset";
            my $format = %lx{'dataset sent'}[0];
            my $msg = sprintf $format, $new-dataset, %params<username>;
            Agrammon::Email.new(
                :to($recipientMail),
                :from('support@agrammon.ch'),
                :$subject,
                :$msg,
                :$attachment,
                :filename($new-dataset.subst(/<-[\w_.-]>/, '', :g) ~ '.pdf')
            ).send;
        }
    }

    method store-dataset-comment(Agrammon::Web::SessionUser $user, Str $name, $comment) {
        return Agrammon::DB::Dataset.new(
            :$user,
            :agrammon-variant($!cfg.agrammon-variant),
            :$name
        ).store-comment($comment);
    }

    method get-tags(Agrammon::Web::SessionUser $user) {
        return Agrammon::DB::Tags.new(:$user).load.list;
    }

    method create-tag(Agrammon::Web::SessionUser $user, Str $name --> Nil) {
        Agrammon::DB::Tag.new(:$user, :$name).create;
    }

    method delete-tag(Agrammon::Web::SessionUser $user, Str $name --> Nil) {
        Agrammon::DB::Tag.new(:$user, :$name).delete;
    }

    method rename-tag(Agrammon::Web::SessionUser $user, Str $old, Str $new --> Nil) {
        Agrammon::DB::Tag.new(:$user, :name($old)).rename($new);
    }

    method set-tag(Agrammon::Web::SessionUser $user, @datasets, Str $tag-name --> Nil) {
        Agrammon::DB::Dataset.new(
            :$user,
            :agrammon-variant($!cfg.agrammon-variant),
        ).set-tag(@datasets, $tag-name);
    }

    method remove-tag(Agrammon::Web::SessionUser $user, @datasets, Str $tag-name --> Nil) {
        Agrammon::DB::Dataset.new(
            :$user,
            :agrammon-variant($!cfg.agrammon-variant),
        ).remove-tag(@datasets, $tag-name);
    }

    method get-input-variables {
        return $!ui-web.get-input-variables;
    }

    method !get-inputs($user, $dataset-name) {
        my $input-dist = Agrammon::DataSource::DB.new.read($user.username, $dataset-name,
                $!cfg.agrammon-variant);
        $input-dist.apply-defaults($!model, %!technical-parameters);
        $input-dist.to-inputs($!model.distribution-map)
    }

    method !get-outputs(Agrammon::Web::SessionUser $user, Str $dataset-name) {
        my $input = self!get-inputs($user, $dataset-name);
        my @validation-errors = validation-errors($!model, $input);
        my $results = $!outputs-cache.get-or-calculate: $user.username, $dataset-name, -> {
            timed "$dataset-name", {
                $!model.run:
                        :$input,
                        technical => %!technical-parameters;
            }
        };

         return {
             :$results,
             :@validation-errors,
        };
    }

    # used in method below
    sub add-module-inputs(Str @inputs, Agrammon::Model::Module $module, Str :$instance-name --> Nil) {
        my @input :=  $module.input;
        return unless @input;

        my $module-name = $module.taxonomy;
        if $instance-name {
            my $root   = $module.instance-root;
            my $instance = $root ~ "[$instance-name]";
            $module-name ~~ s/$root/$instance/;
        }
        for @input -> $input {
            my $line = "$module-name;" ~ $input.name ~ ';';
            $line ~= '"' ~ $input.enum.keys.join(';') ~ '"' if $input.enum;
            @inputs.push($line);
        }
    }

    #| Get a CSV formatted template of all model inputs
    #| with one demo instance for all multi-instance modules.
    method get-input-template($sort) {
        my @modules := $sort eq 'model' ?? $!model.load-order !! $!model.evaluation-order;
        my Str @inputs;
        for @modules -> $module {
            if $module.instance-root -> $root {
                # Multi-instance module
                my $instance-name = 'Demo';
                add-module-inputs(@inputs, $module, :$instance-name);
            }
            else {
                # Single instance module
                add-module-inputs(@inputs, $module);
            }
        }
        @inputs
    }

    method get-latex(Str $technical-file, Str $sort) {
        my $model      = self.model;
        my $model-path = $model.path;
        my $filename   = 'End.nhd';
        my $sections   = 'description';
        my $model-name = 'Agrammon version6';
        my %technical  = load-technical($model-path, $technical-file);
        create-latex-source(
            $model-name,
            $model,
            $sort,
            $sections,
            :%technical
        ) ~ "\n"
    }

    method get-technical(Str $technical) {
        my $model-path = self.model.path;
        $model-path.IO.&child-secure($technical).slurp
    }

    subset InputFormats  of Str where 'application/json' | 'text/csv';
    subset OutputFormats of Str where 'application/json' | 'text/csv' | 'text/plain';

    #| Run model from input data as CSV or JSON
    #| and return output formatted as CSV, JSON, or TEXT
    method get-outputs-for-rest(
        Str $simulation-name, Str $dataset-name, $input-data, InputFormats $type,
        :$model-version, :$variants, :$technical-file,
        :$language = 'de', OutputFormats :$format!, :$print-only,
        :$include-filters = False, :$all-filters = False
    ) {
        my $data-source = do given $type {
            when 'text/csv'         { Agrammon::DataSource::CSV.new }
            when 'application/json' { Agrammon::DataSource::JSON.new }
            default { die "Output format '$type' not supported"; }
        }
        my $input = $data-source.load($simulation-name, $dataset-name, $input-data);

        my $model;
        if $model-version {
            my $model-top   = $!cfg.model-top;
            my $model-path  = self.model.path.IO.parent.&child-secure($model-version).&child-secure($model-top);
            my $module      = $model-path.extension('').basename;
            my $module-path = $model-path.parent;
            $model = timed "Load model variant $variants from $model-path", {
                load-model-using-cache($*HOME.add('.agrammon'), $module-path, $module);
            };
        }
        else {
            $model = $!model;
        }
        my %technical = $technical-file
            ?? load-technical(self.model.path, $technical-file)
            !! %!technical-parameters;

        my @validation-errors = validation-errors($model, $input);
        if @validation-errors {
            warn '**** Got ' ~  @validation-errors.elems ~ ' input validation errors' if @validation-errors;
            for @validation-errors {
                note .message;
            }
        }

        $input.apply-defaults($model, %technical);
        my $outputs = $!model.run(:$input, :%technical);

        my @print-set = ($print-only).split(',') if $print-only;
        my $result;
        given $format {
            when 'text/csv' {
                die "CSV output including filters is not yet supported" if $include-filters;
                $result = output-as-csv(
                    $simulation-name, $dataset-name, $!model,
                    $outputs, $language, @print-set, $include-filters, :$all-filters
                ) ~ "\n";
            }
            when 'application/json' {
                $result = output-as-json(
                    $!model, $outputs, $language, @print-set, $include-filters, :$all-filters
                );
            }
            when 'text/plain' {
                $result = output-as-text(
                    $!model, $outputs, $language, @print-set, $include-filters, :$all-filters
                ) ~ "\n";
            }
        }

        return $result;
    }

    method get-output-variables(Agrammon::Web::SessionUser $user, Str $dataset-name) {
        my $results = self!get-outputs($user, $dataset-name)<results>;
        my $validation-errors = self!get-outputs($user, $dataset-name)<validation-errors>;
        warn '**** Got ' ~  $validation-errors.elems ~ ' input validation errors' if $validation-errors;
        dd 'Validation errors:', $validation-errors if $validation-errors;
        # TODO: get with-filters from frontend
        # TODO: deal with validation errors in frontend; needs translations
        my %gui-output = output-for-gui($!model, $results, :include-filters);
        note '**** with-filters for get-output-variables() not yet completely implemented';
        return %gui-output;
    }

    method get-excel-export(Agrammon::Web::SessionUser $user, %params) {
        my $dataset-name    = %params<datasetName>;
        my $language        = %params<language>;
        my $report-selected = %params<reportSelected>.Int;

        my $inputs  = self!get-inputs($user, $dataset-name);
        my $outputs = self!get-outputs($user, $dataset-name)<results>;
        my $reports = self.get-input-variables<reports>;

        my $type = $reports[$report-selected]<type> // '';
        my $with-filters = $type eq 'reportDetailed';
        my $all-filters = $type eq 'reportDetailed';

        input-output-as-excel(
            $!cfg,
            $user,
            $dataset-name,
            $!model, $outputs, $inputs, $reports,
            $language, $report-selected,
            $with-filters, $all-filters
        );
    }

    method get-pdf-export(Agrammon::Web::SessionUser $user, %params) {
        my $dataset-name    = %params<datasetName>;
        my $language        = %params<language>;
        my $report-selected = %params<reportSelected>.Int;

        my %submission;
        if %params<mode> and %params<mode> eq 'submission' {
            my $sender-name = %params<senderName>;
            # replace URL pseudo-encoded newlines from frontend
            $sender-name ~~ s:g/XXX/\\newline\{\}/;
            my $comment = %params<comment>;
            $comment ~~ s:g/XXX/\\newline\{\}/;
            my $dataset-name = submission-dataset(%params);
            %submission =
                :farm-number(%params<farmNumber>),
                :farm-situation(%params<farmSituation>),
                :$comment,
                :$sender-name,
                :recipient-name(%params<recipientName>),
                :recipient-email(%params<recipientEmail>),
                :$dataset-name;
        }

        my $inputs  = self!get-inputs($user, $dataset-name);
        my $outputs = self!get-outputs($user, $dataset-name)<results>;
        my $reports = self.get-input-variables<reports>;

        my $type = $reports[$report-selected]<type> // '';
        my $with-filters = $type eq 'reportDetailed';
        my $all-filters  = $type eq 'reportDetailed';

        input-output-as-pdf(
            $!cfg,
            $user,
            $dataset-name,
            $!model, $outputs, $inputs, $reports,
            $language, $report-selected,
            $with-filters, $all-filters, :%submission
       );
    }

    method create-account($user, $email, $password, $firstname, $lastname, $org, $role?) {
        return Agrammon::DB::User.new(
            :username($email), :$password,
            :$firstname, :$lastname,
            :organisation($org)
        ).create-account($role).username;
    }

    method get-account-key($email, $password, $language) {
        my $key = Agrammon::DB::User.new(:username($email), :$password).get-account-key;

        # set in t/webservice.t to avoid sending email
        if not %*ENV<AGRAMMON_TESTING> {
            my %params;
            my %lx = $!cfg.translations{$language // 'de'};
            my $subject = %lx{'Agrammon account key'};
            my $msg = %lx{'enter account key'} ~ " $key";
            Agrammon::Email.new(
                :to($email),
                :from('support@agrammon.ch'),
                :$subject,
                :$msg
            ).send;
        }
    }

    method change-password(Agrammon::Web::SessionUser $user, Str $old-password, Str $new-password --> Nil) {
        $user.change-password($old-password, $new-password);
    }

    method reset-password($user, Str $email, Str $password, $key?) {
        return $user.reset-password($email, $password, $key);
    }

    method store-data(Agrammon::Web::SessionUser $user, $dataset-name, $variable, $value, @branches?, @options?, $row? --> Nil) {
        my $ds = Agrammon::DB::Dataset.new(
            :$user,
            :agrammon-variant($!cfg.agrammon-variant),
            :name($dataset-name)
        );
        $ds.store-input($variable, $value, @branches, @options);

        $!outputs-cache.invalidate($user.username, $dataset-name);
    }

    method store-input-comment(Agrammon::Web::SessionUser $user, $dataset, $variable, $comment --> Nil) {
        Agrammon::DB::Dataset.new(
            :$user,
            :agrammon-variant($!cfg.agrammon-variant),
            :name($dataset)
        ).store-input-comment($variable, $comment);
    }

    method delete-instance(Agrammon::Web::SessionUser $user, $dataset-name, $variable-pattern, $instance --> Nil) {
        Agrammon::DB::Dataset.new(
            :$user,
            :agrammon-variant($!cfg.agrammon-variant),
            :name($dataset-name)
        ).delete-instance($variable-pattern, $instance);
        $!outputs-cache.invalidate($user.username, $dataset-name);
    }

    method load-branch-data(Agrammon::Web::SessionUser $user, Str $name, %data) {
        return Agrammon::DB::Dataset.new(
            :$user,
            :agrammon-variant($!cfg.agrammon-variant),
            :$name
        ).lookup.load-branch-data(%data<vars>, %data<instance>);
    }

    method store-branch-data(Agrammon::Web::SessionUser $user, Str $name, %data) {
        Agrammon::DB::Dataset.new(
            :$user,
            :agrammon-variant($!cfg.agrammon-variant),
            :$name
        ).lookup.store-branch-data(%data<vars>, %data<instance>, %data<options>, %data<data>);
        $!outputs-cache.invalidate($user.username, $name);
    }

    method rename-instance(Agrammon::Web::SessionUser $user, Str $dataset-name, Str $old-instance, Str $new-instance, Str $variable-pattern --> Nil) {
        Agrammon::DB::Dataset.new(
            :$user,
            :agrammon-variant($!cfg.agrammon-variant),
            :name($dataset-name)
        ).rename-instance($old-instance, $new-instance, $variable-pattern);
    }

    method order-instances(Agrammon::Web::SessionUser $user, Str $dataset-name, @instances) {
        Agrammon::DB::Dataset.new(
            :$user,
            :agrammon-variant($!cfg.agrammon-variant),
            :name($dataset-name)
        ).order-instances(@instances);
    }

    method upload-dataset(Agrammon::Web::SessionUser $user, Str $dataset-name, $content, $comment) {
        Agrammon::DB::Dataset.new(
            :$user,
            :agrammon-variant($!cfg.agrammon-variant),
            :name($dataset-name),
            :$comment
        ).create.upload-data($content);
    }

    sub submission-dataset(%params --> Str) {
        %params<farmNumber>    ~ ', ' ~
        %params<farmSituation> ~ ', ' ~
        %params<username>      ~ ', ' ~
        %params<datasetName>   ~ ', ' ~
        timestamp
    }

}
