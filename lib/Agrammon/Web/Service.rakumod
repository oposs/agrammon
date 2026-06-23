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
use Agrammon::OutputFormatter::ExcelNative;
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
    # Lazily-built map of full input-variable path -> Agrammon::Model::Input,
    # used to re-key branch matrices onto the current model enum order.
    has %!branch-input-by-path;
    has Bool $!branch-input-cache-built = False;

    #| return config hash as expected by Web GUI
    method get-cfg() {
        my %gui   = $!cfg.gui;
        my %model = $!cfg.model;
        my %cfg = (
            guiVariant   => %gui<variant>,
            modelVariant => %model<variant>,
            title        => $!cfg.gui-title,
            variant      => %model<variant>,
            version      => %model<version>,
            guiVersion   => $!cfg.gui-version,
            submission   => %gui<submission>,
            baseUrl      => %gui<baseUrl>,
            versions     => $!cfg.versions-resolved,
        );
        return %cfg;
    }

    #| return list of datasets as expected by Web GUI
    method get-datasets(Agrammon::Web::SessionUser $user) {
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
            # #571: name the source model variant + URL so the recipient knows
            # which Agrammon instance the dataset came from.
            $msg ~= "\n\n" ~ self!model-info-line($language);
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
                         $current-username, Str $new-username,
                         Str $old-dataset, Str $new-dataset --> Nil) {
        Agrammon::DB::Dataset.new(
            :$user,
            :agrammon-variant($!cfg.agrammon-variant)
        ).clone(:$current-username, :$new-username, :$old-dataset, :$new-dataset);
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
        self.clone-dataset($user, $user.username, $recipientMail, $old-dataset, $new-dataset);

        # set in t/webservice.t to avoid sending email
        if not %*ENV<AGRAMMON_TESTING> {
            my $attachment = self.get-pdf-export($user, %params);
            my $subject = %lx<dataset> ~ ": $new-dataset";
            my $format = %lx{'dataset sent'}[0];
            my $msg = sprintf $format, $new-dataset, %params<username>;
            # #571: name the source model variant + URL so the recipient knows
            # which Agrammon instance the dataset came from.
            $msg ~= "\n\n" ~ self!model-info-line(%params<language> // 'de');
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

    #| #571: one localized line naming the source model variant and its URL,
    #| appended to dataset-sent emails so the recipient can tell which Agrammon
    #| instance (Single/Regional/Kantonal, version) a dataset came from.
    method !model-info-line(Str $language) {
        my %lx     = $!cfg.translations{$language} // $!cfg.translations<en>;
        my %titles = $!cfg.gui-title;
        my $title  = %titles{$language} // %titles<en> // $!cfg.gui-variant;
        my $url    = $!cfg.gui-url // '';
        return sprintf %lx{'dataset model info'}, $title, $url;
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
    #| CSV format has one demo instance for all multi-instance modules.
    method get-input-template($sort, $format, $language) {
        my $model = self.model;
        given $format {
            when 'json' { $model.dump-json($sort, $language) };
            when 'text' { $model.dump($sort, $language) };
            when 'csv'  {
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
                @inputs.join("\n") ~ "\n";
            }
        }
    }

    method get-latex(Str $technical-file, Str $sort) {
        my $model      = self.model;
        my $model-path = $model.path;
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
    subset OutputFormats of Str where 'application/json' | 'text/csv' | 'text/plain' | 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

    #| Run model from input data as CSV or JSON
    #| and return output formatted as CSV, JSON, or TEXT
    method get-outputs-for-rest(
        Str $simulation-name, Str $dataset-name, $input-data, InputFormats $type,
        :$model-version, :$variants, :$technical-file,
        :$language = 'de', OutputFormats :$format!, :$print-only, :$report-selected, :$user,
        :$include-filters = False, :$all-filters = False, :$compact-output
    ) {
        my $data-source = do given $type {
            when 'text/csv'         { Agrammon::DataSource::CSV.new }
            when 'application/json' { Agrammon::DataSource::JSON.new }
            when 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' { Agrammon::DataSource::Excel.new }
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
                load-model-using-cache(agrammon-cache-dir(), $module-path, $module);
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
#                die "CSV output including filters is not yet supported" if $include-filters;
                $result = output-as-csv(
                    $simulation-name, $dataset-name, $!model,
                    $outputs, $language, @print-set, $include-filters, :$all-filters
                ) ~ "\n";
            }
            when 'application/json' {
                $result = output-as-json(
                    $!model, $outputs, $language, @print-set, $include-filters, :$all-filters,
                    :compact-output( ($compact-output // '') eq 'true')
                );
            }
            when 'text/plain' {
                $result = output-as-text(
                    $!model, $outputs, $language, @print-set, $include-filters, :$all-filters
                ) ~ "\n";
            }
            when 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' {
                my $reports = self.get-input-variables<reports>;
                $result = input-output-as-excel(
                    $!cfg, $user, $dataset-name,
                     $!model, $outputs,
                     $input,
                     $reports,
                     $language,
                     $report-selected.Int,
                     $include-filters, $all-filters
                );
            }
        }

        return $result;
    }

    #| Run *all* datasets contained in a single REST payload concurrently against
    #| one shared, read-only model (issue #569). Mirrors the CLI's
    #| `race ... .race(:degree)` pattern: $model.run is reentrant (fresh Outputs
    #| per run, per-call dynamic vars), so no extra locking is needed. Returns an
    #| ordered list of per-dataset result hashes — `{ simulation, dataset, data }`
    #| on success or `{ simulation, dataset, validationErrors }` when a dataset
    #| fails validation — so one bad dataset never aborts the whole batch.
    method get-batch-outputs-for-rest(
        $input-data, InputFormats $type,
        :$model-version, :$variants, :$technical-file,
        :$language = 'de', OutputFormats :$format!, :$print-only, :$report-selected, :$user,
        :$include-filters = False, :$all-filters = False, :$compact-output, :$degree
    ) {
        my @inputs = do given $type {
            when 'text/csv'         { Agrammon::DataSource::CSV.new.read-data($input-data) }
            when 'application/json' { Agrammon::DataSource::JSON.new.load-data($input-data) }
            default { die "Batch run is not supported for input format '$type'"; }
        }

        my $model;
        if $model-version {
            my $model-top   = $!cfg.model-top;
            my $model-path  = self.model.path.IO.parent.&child-secure($model-version).&child-secure($model-top);
            my $module      = $model-path.extension('').basename;
            my $module-path = $model-path.parent;
            $model = timed "Load model variant $variants from $model-path", {
                load-model-using-cache(agrammon-cache-dir(), $module-path, $module);
            };
        }
        else {
            $model = $!model;
        }
        my %technical = $technical-file
            ?? load-technical(self.model.path, $technical-file)
            !! %!technical-parameters;

        my @print-set = ($print-only).split(',') if $print-only;

        # Bound the concurrency so a single request cannot starve the server.
        # Coerce defensively: a missing or non-numeric degree falls back to 4.
        my $degree-bounded = (try { ($degree // 4).Int }) // 4;
        $degree-bounded = 1  if $degree-bounded < 1;
        $degree-bounded = 16 if $degree-bounded > 16;

        my @results = Any xx @inputs.elems;   # pre-sized: distinct-index writes are safe
        return @results unless @inputs;

        # The model + output machinery build several lazy caches on first use
        # (e.g. the `||=` output-label/format/order caches) that are not safe to
        # build concurrently. So run the FIRST dataset single-threaded to warm
        # all of that shared state — its result is kept, not wasted — and only
        # then race the remaining datasets against the now-warm model. (#569)
        @results[0] = self!run-one-for-rest(
            @inputs[0], $model, %technical, $language, $format, @print-set,
            $include-filters, $all-filters, $compact-output
        );
        race for (1 ..^ @inputs.elems).race(:degree($degree-bounded), :1batch) -> $i {
            @results[$i] = self!run-one-for-rest(
                @inputs[$i], $model, %technical, $language, $format, @print-set,
                $include-filters, $all-filters, $compact-output
            );
        }
        return @results;
    }

    #| Validate, run and format a single dataset for a REST batch. Validation
    #| and run failures are captured into the result hash (validationErrors /
    #| error) so that one bad dataset never aborts the whole batch. (#569)
    method !run-one-for-rest(
        $input, $model, %technical, $language, $format, @print-set,
        $include-filters, $all-filters, $compact-output
    ) {
        my @validation-errors = validation-errors($model, $input);
        if @validation-errors {
            return %(
                simulation       => $input.simulation-name,
                dataset          => $input.dataset-id,
                validationErrors => @validation-errors.map(*.message).List,
            );
        }
        my $data;
        my $run-error;
        {
            $input.apply-defaults($model, %technical);
            my $outputs = $model.run(:$input, :%technical);
            $data = self!format-rest-output(
                $format, $input, $model, $outputs,
                $language, @print-set, $include-filters, $all-filters, $compact-output
            );
            CATCH { default { $run-error = .message } }
        }
        return $run-error.defined
            ?? %( simulation => $input.simulation-name, dataset => $input.dataset-id, error => $run-error )
            !! %( simulation => $input.simulation-name, dataset => $input.dataset-id, data => $data );
    }

    #| Format the outputs of one dataset for a REST (batch) response. JSON returns
    #| the structured records (serialised by the route); CSV/text return a string.
    method !format-rest-output(
        $format, $input, $model, $outputs,
        $language, @print-set, $include-filters, $all-filters, $compact-output
    ) {
        given $format {
            when 'text/csv' {
                return output-as-csv(
                    $input.simulation-name, $input.dataset-id, $model,
                    $outputs, $language, @print-set, $include-filters, :$all-filters
                ) ~ "\n";
            }
            when 'application/json' {
                return output-as-json(
                    $model, $outputs, $language, @print-set, $include-filters, :$all-filters,
                    :compact-output( ($compact-output // '') eq 'true')
                );
            }
            when 'text/plain' {
                return output-as-text(
                    $model, $outputs, $language, @print-set, $include-filters, :$all-filters
                ) ~ "\n";
            }
            default { die "Batch run is not supported for output format '$format'"; }
        }
    }

    method get-output-variables(Agrammon::Web::SessionUser $user, Str $dataset-name) {
        my $outputs = self!get-outputs($user, $dataset-name);
        my $results = $outputs<results>;
        my $validation-errors = $outputs<validation-errors>;
        # Write validation errors to log file for the moment to help debug
        # broken production datasets.
	if $validation-errors {
	    note '**** Got ' ~  $validation-errors.elems ~ ' input validation errors';
            dd 'Validation errors:', $validation-errors;
	    # TODO: deal with validation errors in frontend; needs translations
        }
        # TODO: get with-filters from frontend
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

    method self-create-account($email, $password, $firstname, $lastname, $org, $language, $role?) {
        my $key = Agrammon::DB::User.new(
            :username($email), :$password,
            :$firstname, :$lastname,
            :organisation($org)
        ).self-create-account($role);
        if not %*ENV<AGRAMMON_TESTING> {
            my $subject = "Agrammon account activation";
            # start link on new line to avoid . at beginning of second line
            # of the encode string (seems to disappear in the received
            # email) ... Fritz, 2025-01-14
            my $url = $!cfg.gui-url;

            my %text = %(
                de => "Klicken Sie auf den folgenden Link, um ihr Agrammon Konto zu aktivieren:",
                en => "Click on the following link to activate your Agrammon account:",
                fr => "Cliquez sur le lien suivant pour activer votre compte Agrammon:",
            );
            my $msg = (%text{$language} // %text<en>) ~ "\n\n$url/activate_account?key=$key";
            Agrammon::Email.new(
                :to($email),
                :from('support@agrammon.ch'),
                :$subject,
                :$msg,
            ).send;
        }
        return $key;
    }

    method create-account($email, $password, $firstname, $lastname, $org, $language, $role?) {
        return Agrammon::DB::User.new(
            :username($email), :$password,
            :$firstname, :$lastname,
            :organisation($org)
        ).create-account($role).username;
    }

    method activate-account($key) {
        my $username= Agrammon::DB::User.new.activate-account($key);
        if $username {
            return $!cfg.gui-url;
        }
        return;
    }

    method change-password(Agrammon::Web::SessionUser $user, Str $old-password, Str $new-password --> Nil) {
        $user.change-password($old-password, $new-password);
    }

    method reset-password($user, Str $email, Str $password, $key?) {
        return $user.reset-password($email, $password, $key);
    }

    method self-reset-password(Str $email, Str $password, Str $language) {
        # note "Service: selfService resetting password for $email";
        my $key = Agrammon::DB::User.new(
            :username($email), :password('dummy')
        ).self-reset-password($password);
        # note "Service: New password set for $email: activation key=$key";
        if not %*ENV<AGRAMMON_TESTING> {
            my $subject = "Agrammon password reset";
            my $url = $!cfg.gui-url;
            my %text = %(
                de => "Klicken Sie auf den folgenden Link, um das Zurücksetzen Ihres Agrammon-Passworts zu bestätigen:",
                en => "Click on the following link to confirm your Agrammon password reset:",
                fr => "Cliquez sur le lien suivant pour confirmer la réinitialisation de votre mot de passe Agrammon:",
            );
            my $msg = (%text{$language} // %text<en>) ~ "\n\n$url/activate_account?key=$key";
            Agrammon::Email.new(
                :to($email),
                :from('support@agrammon.ch'),
                :$subject,
                :$msg,
            ).send;
        }
        return $key;
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

    method delete-dataset-variables(Agrammon::Web::SessionUser $user, Str $dataset-name, @variables --> Int) {
        my $deleted = Agrammon::DB::Dataset.new(
            :$user,
            :agrammon-variant($!cfg.agrammon-variant),
            :name($dataset-name)
        ).delete-variables(@variables);
        $!outputs-cache.invalidate($user.username, $dataset-name) if $deleted;
        return $deleted;
    }

    method !branch-input(Str $path) {
        unless $!branch-input-cache-built {
            for $!model.load-order -> $module {
                my $tax  = $module.taxonomy;
                my $root = $module.instance-root;
                $tax ~~ s/$root/$root\[\]/ if $root;
                for $module.input -> $input {
                    %!branch-input-by-path{"$tax\::{$input.name}"} = $input;
                }
            }
            $!branch-input-cache-built = True;
        }
        return %!branch-input-by-path{$path};
    }

    method load-branch-data(Agrammon::Web::SessionUser $user, Str $name, %data) {
        my $raw = Agrammon::DB::Dataset.new(
            :$user,
            :agrammon-variant($!cfg.agrammon-variant),
            :$name
        ).lookup.load-branch-data(%data<vars>, %data<instance>);

        # The DB layer returns the matrix oriented to the requested @vars order.
        # Re-key it onto each axis variable's CURRENT model enum order: cells are
        # matched by canonical option key, so a branch reads correctly even when
        # the enum order changed, options were added/removed, or cross-version
        # aliases apply (options with no stored value come back as 0). This keeps
        # branch display stable across model changes without touching stored data.
        return $raw unless $raw<fractions>.defined;
        my @vars = %data<vars>.list;
        my $in0  = self!branch-input(@vars[0]);
        my $in1  = self!branch-input(@vars[1]);
        return $raw unless $in0 && $in1 && $in0.enum && $in1.enum;

        my @k0   = $in0.enum-ordered.map(*.key);   # vars[0] keys, model order
        my @k1   = $in1.enum-ordered.map(*.key);   # vars[1] keys, model order
        my @s0   = $raw<options>[0].list;          # stored ROW-axis option keys
        my @s1   = $raw<options>[1].list;          # stored COL-axis option keys
        my @frac = $raw<fractions>.list;           # stored matrix, row-major [@s0]x[@s1]

        # The stored row/col *variable* assignment can be crossed (e.g. branches
        # migrated from the old layout), so decide which requested variable each
        # stored axis belongs to by matching its option keys against each model
        # enum — not by the stored row/col designation.
        my $row-is-v0 =  @s0.grep({ $in0.canonical-enum-value($_).defined }).elems
                      >= @s0.grep({ $in1.canonical-enum-value($_).defined }).elems;
        my ($row-in, $col-in) = $row-is-v0 ?? ($in0, $in1) !! ($in1, $in0);

        # Build (canonical vars[0] key, canonical vars[1] key) -> value.
        my %cell;
        my $ncol = @s1.elems;
        for ^@s0.elems -> $r {
            my $rk = $row-in.canonical-enum-value(@s0[$r]) // @s0[$r];
            for ^$ncol -> $c {
                my $ck  = $col-in.canonical-enum-value(@s1[$c]) // @s1[$c];
                my $val = @frac[$r * $ncol + $c];
                if $row-is-v0 { %cell{$rk}{$ck} = $val }
                else          { %cell{$ck}{$rk} = $val }
            }
        }
        # Emit in the current model enum order; options with no stored value -> 0.
        my @fractions;
        for @k0 -> $a {
            for @k1 -> $b {
                @fractions.push: %cell{$a}{$b} // 0e0;
            }
        }
        return { fractions => @fractions, options => [@k0, @k1] };
    }

    method store-branch-data(Agrammon::Web::SessionUser $user, Str $name, %data) {
        Agrammon::DB::Dataset.new(
            :$user,
            :agrammon-variant($!cfg.agrammon-variant),
            :$name
        ).lookup.store-branch-data(%data<vars>, %data<instance>, %data<options>, %data<data>);
        $!outputs-cache.invalidate($user.username, $name);
    }

    method store-flattened-data(Agrammon::Web::SessionUser $user, Str $name, %data) {
        Agrammon::DB::Dataset.new(
            :$user,
            :agrammon-variant($!cfg.agrammon-variant),
            :$name
        ).lookup.store-flattened-data(%data<var>, %data<instance>, %data<options>, %data<fractions>);
        $!outputs-cache.invalidate($user.username, $name);
    }

    method copy-branch-data(Agrammon::Web::SessionUser $user, Str $name, %data) {
        Agrammon::DB::Dataset.new(
            :$user,
            :agrammon-variant($!cfg.agrammon-variant),
            :$name
        ).lookup.copy-instance-branches(%data<sourceInstance>, %data<targetInstance>);
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
