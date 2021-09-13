use v6;
use Cro::HTTP::Log::File;
use Cro::HTTP::Router;
use Cro::HTTP::Server;
use Cro::HTTP::Session::InMemory;
use DB::Pg;
use JSON::Fast;

use Agrammon::Config;
use Agrammon::DataSource::DB;
use Agrammon::DataSource::CSV;
use Agrammon::Documentation;
use Agrammon::ModelCache;
use Agrammon::OutputFormatter::CSV;
use Agrammon::OutputFormatter::JSON;
use Agrammon::OutputFormatter::Text;
use Agrammon::OutputFormatter::Util;
use Agrammon::Performance;
use Agrammon::ResultCollector;
use Agrammon::TechnicalParser;
use Agrammon::Validation;
use Agrammon::Web::APIRoutes;
use Agrammon::Web::APITokenManager;
use Agrammon::Web::Routes;
use Agrammon::Web::SessionStore;
use Agrammon::Web::SessionUser;


my %*SUB-MAIN-OPTS =
  :named-anywhere,    # allow named variables at any location
;

subset ExistingFile        of Str where { !.defined or .IO.e or note("No such file $_") && exit 1 }
subset ExistingFileOrStdin of Str where { !.defined or .IO.e or $_ eq '-' or note("No such file $_") && exit 1 }
subset SupportedLanguage of Str where { $_ ~~ /^ de|en|fr $/ or note("ERROR: --language=[de|en|fr]") && exit 1 };
subset SortOrder of Str where { $_ ~~ /^ model|calculation $/ or note("ERROR: --sort=[model|calculation]") && exit 1 };
subset OutputFormat of Str where { $_ ~~ /^ csv|json|text $/ or note("ERROR: --format=[csv|json|text]") && exit 1 };

#| Start the web interface
multi sub MAIN('web', Str $model-filename, ExistingFile :$cfg-file, Str :$technical-file) is export {
    my $http = web($cfg-file, $model-filename, $technical-file);
    react {
        whenever signal(SIGINT) {
            say "Shutting down...";
            $http.stop;
            done;
        }
    }
}

#| Run the model
multi sub MAIN('run', Str $filename, ExistingFileOrStdin $input, ExistingFile :$cfg-file, Str :$technical-file,
        SupportedLanguage :$language = 'de', Str :$print-only, Str :$variants = 'Base',
        Bool :$include-filters, Bool :$include-all-filters=False, Int :$batch=1, Int :$degree=4, Int :$max-runs,
        OutputFormat :$format = 'text'
    ) is export {
    my @print-set = $print-only.split(',') if $print-only;
    my $data = run $filename, $input.IO, $technical-file, $variants, $format, $language, @print-set,
            ($include-filters or $include-all-filters),
            $batch, $degree, $max-runs, :$cfg-file, :all-filters($include-all-filters);
    my %results := $data.results;
    my %validation-errors := $data.validation-errors;

    my $output;
    if $format eq 'json' {
        $output = to-json $data.results;
    }
    else {
        my @output;
        @output.push("##  Model: $filename");
        @output.push("##  Variants: $variants");

        if %validation-errors {
            for %validation-errors.kv -> $simulation, %sim-errors {
                @output.push("### Simulation $simulation");
                for %sim-errors.keys.sort -> $dataset {
                    @output.push("#   Dataset $dataset");
                    for @(%sim-errors{$dataset}) -> $error {
                        # TODO: add translations
                        @output.push('#   ' ~ $error.message);
                    }
                }
            }
        }
        else {
            for %results.kv -> $simulation, %sim-results {
                @output.push("### Simulation $simulation");
                @output.push("##  Print filter: $print-only") if $print-only;
                for %sim-results.keys.sort -> $dataset {
                    @output.push("#   Dataset $dataset");
                    @output.push(%sim-results{$dataset});
                }
            }
        }
        $output = @output.join("\n");
    }
    say $output;
}

#| Get inputs from dataset
multi sub MAIN(
        'getDataset', Str $model-filename, Str $username, Str $dataset-name,
        Str $version, Str $gui, Str $variant, ExistingFile :$cfg-file
    ) is export {
    my %data := get-dataset $model-filename, $username, $dataset-name, $version, $gui, $variant, :$cfg-file;
    my @output;
    @output.push("## User: %data<username>");
    @output.push("## Dataset: %data<dataset>");
    if %data<validation-errors> {
        note "WARNING: validation errors";
        @output.push('## Validation errors');
        for @(%data<validation-errors>) -> $error {
            @output.push($error.message);
        }
        @output.push('##');
    }
    my $inputs = %data<inputs>;
    for $inputs.kv -> $module, $_ {
        when Hash {
            for sorted-kv($_) -> $input, $value {
                @output.push("$module;$input;$value");
            }
        }
        when Array {
            for sorted-kv($_) -> $instance-id, %instance-inputs {
                for sorted-kv(%instance-inputs) -> $fq-name, %values {
                    my $q-name = module-with-instance($module, $instance-id, $fq-name);
                    for sorted-kv(%values) -> $input, $value {
                        @output.push("$q-name;$input;$value");
                    }
                }
            }
        }
    }
    say @output.join("\n");
}

#| Validate inputs
multi sub MAIN(
        'validate', Str $filename, ExistingFileOrStdin $input, ExistingFile :$cfg-file,
        SupportedLanguage :$language = 'de', Str :$variants = 'Base',
        Int :$batch=1, Int :$degree=4, Int :$max-runs
    ) is export {
    my %validation-errors = validate $filename, $input.IO, $variants,
            $batch, $degree, $max-runs, :$cfg-file;
    my @output;
    @output.push("##  Model: $filename");
    @output.push("##  Variants: $variants");
    if %validation-errors {
        for %validation-errors.kv -> $simulation, %sim-errors {
            @output.push("### Simulation $simulation");
            for %sim-errors.keys.sort -> $dataset {
                @output.push("#   Dataset $dataset");
                # TODO: add translations
                @output.push(%sim-errors{$dataset}.message);
            }
        }
    }
    else {
        @output.push('##  No validation errors');
    }
    say @output.join("\n");
}

#| Dump model
multi sub MAIN('dump', Str $filename, ExistingFile :$cfg-file, Str :$variants = 'Base', SortOrder :$sort = 'model') is export {
    my ($model) = load-model($cfg-file, $filename, $variants);
    say chomp $model.dump($sort);
}

#| Create LaTeX documentation
multi sub MAIN(
        'latex', Str $filename, ExistingFile :$cfg-file, Str :$technical-file, Str :$sections = 'description',
        Str :$variants = 'Base', SortOrder :$sort = 'model'
    ) is export {
    my $model-name = ~$filename.IO.parent;
    my ($model, $module-path) = load-model($cfg-file, $filename, $variants);
    my %technical = load-technical($module-path, $technical-file);

    say create-latex-source(
        $model-name,
        $model,
        $sort,
        $sections,
        :%technical
    );
}

#| Create Agrammon user
multi sub MAIN(
        'create-user', Str $username,
        Str $firstname, Str $lastname, Str $password, Str $role?, ExistingFile :$cfg-file
    ) is export {
    create-user($cfg-file, $username, $firstname, $lastname, $password, $role);
}

#| Set Agrammon user password
multi sub MAIN('set-password', Str $username, Str $password, ExistingFile :$cfg-file) is export {
    set-password($cfg-file, $username, $password);
}

#| Create an API token for the specified username.
multi sub MAIN('issue-api-token', Str $username, ExistingFile :$cfg-file) is export {
    issue-api-token($cfg-file, $username);
}

sub USAGE() is export {
    say "$*USAGE\n" ~ chomp q:to/USAGE/;
        See https://www.agrammon.ch for more information about Agrammon.
    USAGE
}

sub create-user($cfg-file, $username, $firstname, $lastname, $password, $role?) {
    get-cfg-and-db-handle($cfg-file);
    my $user = Agrammon::DB::User.new(
        :$username, :$firstname, :$lastname, :$password
    );
    $user.create-account($role);
    CATCH {
        when X::Agrammon::DB::User::Exists  {
            note "User $username already exists";
            return 1;
        }
    }
    say "User $username created";
}

sub set-password($cfg-file, $username, $password) {
    get-cfg-and-db-handle($cfg-file);
    Agrammon::DB::User.new(:$username).reset-password($username, $password);
    say "New password set for user $username";
}

sub issue-api-token($cfg-file, $username) {
    get-cfg-and-db-handle($cfg-file);
    my $user = Agrammon::DB::User.new(:$username);
    unless $user.exists {
        note "No such user '$username'";
        exit 1;
    }
    my $token = get-api-token-manager().create-token(:metadata{ :$username });
    note "Issued token $token.token()";
}

sub load-model($cfg-file, $model-filename, $variants? is copy ) {
    die "ERROR: load-model expects a .nhd file" unless $model-filename.IO.extension eq 'nhd';
    my ($cfg, $db) = get-cfg-and-db-handle($cfg-file);
    $variants //= $cfg.model-variant;

    my $module-path = $cfg.model-path.IO.add($model-filename);
    die "Model not found at $module-path" unless $module-path.e;

    my $module     = $module-path.extension('').basename;
    my $model-path = $module-path.parent;
    my $model = timed "Load model variant $variants from $module-path", {
        load-model-using-cache($*HOME.add('.agrammon'), $model-path, $module, preprocessor-options($variants));
    };
    return ($model, $module-path, $cfg, $db);
}

sub get-dataset (
        Str $model-filename, Str $username, Str $name,
        Str $version, Str $gui, Str $variants,
        Str $technical-file = 'technical.cfg', Str :$cfg-file
    ) {
    my ($model, $module-path, $cfg, $db) = load-model($cfg-file, $model-filename, $variants);
    my %technical-parameters = load-technical($module-path.IO.parent, $technical-file);

    my $input-dist = Agrammon::DataSource::DB.new.read($username, $name, $cfg.agrammon-variant);
    $input-dist.apply-defaults($model, %technical-parameters);
    my $inputs = $input-dist.to-inputs($model.distribution-map);
    my @validation-errors = validation-errors($model, $inputs);
    return %(
        :$username,
        :dataset("$name, version $version, variant $variants"),
        :validation-errors(@validation-errors),
        :inputs($inputs.all-inputs),
    );
}

sub run (Str $model-filename, IO::Path $input-path, $technical-file, $variants, $format, $language, @print-set,
         Bool $include-filters, $batch, $degree, $max-runs, :$all-filters, Str :$cfg-file) {

    my ($model, $module-path) = load-model($cfg-file, $model-filename, $variants);
    my %technical = load-technical($module-path.IO.parent, $technical-file);

    my $fh = get-input-filehandle($input-path);
    LEAVE $fh.?close;
    my $ds = Agrammon::DataSource::CSV.new;

    my $rc = Agrammon::ResultCollector.new;
    my atomicint $n = 0;
    my class X::EarlyFinish is Exception {}
    race for $ds.read($fh).race(:$batch, :$degree) -> $input {
        my $my-n = ++⚛$n;
        if validation-errors($model, $input) -> @validation-errors {
            $rc.add-validation-errors($input.simulation-name, $input.dataset-id, @validation-errors);
        }
        else {
            my $outputs = timed "$my-n: Run $input-path", {
                $input.apply-defaults($model, %technical);
                $model.run(:$input, :%technical);
            }

            timed "Create output", {
                my $result;
                given $format {
                    when 'csv' {
                        $result = output-as-csv(
                            $input.simulation-name, $input.dataset-id, $model,
                            $outputs, $language, @print-set, $include-filters, :$all-filters
                        );
                    }
                    when 'json' {
                        $result = output-as-json(
                            $model, $outputs, $language, @print-set, $include-filters, :$all-filters
                        );
                    }
                    when 'text' {
                        $result = output-as-text(
                            $model, $outputs, $language, @print-set, $include-filters, :$all-filters
                        );
                    }
                }
                $rc.add-result($input.simulation-name, $input.dataset-id, $result);
            };
        }
        if $max-runs and $my-n == $max-runs {
            note "Finished after $my-n datasets";
            die X::EarlyFinish.new;
        };
    }
    return $rc;
    CATCH {
        when X::EarlyFinish { return $rc }
    }
}

sub validate (Str $model-filename, IO::Path $input-path, $variants, $batch, $degree, $max-runs, Str :$cfg-file) is export {
    my ($model) = load-model($cfg-file, $model-filename, $variants);

    my $fh = get-input-filehandle($input-path);
    LEAVE $fh.?close;
    my $ds = Agrammon::DataSource::CSV.new;

    my $rc = Agrammon::ResultCollector.new;
    my atomicint $n = 0;
    my class X::EarlyFinish is Exception {}
    race for $ds.read($fh).race(:$batch, :$degree) -> $dataset {
        my $my-n = ++⚛$n;
        if validation-errors($model, $dataset) -> @validation-errors {
            $rc.add-validation-errors($dataset.simulation-name, $dataset.dataset-id, @validation-errors);
        }

        if $max-runs and $my-n == $max-runs {
            note "Finished after $my-n datasets";
            die X::EarlyFinish.new;
        };
    }
    return $rc.validation-errors;
    CATCH {
        when X::EarlyFinish { return $rc.validation-errors }
    }
}

sub get-cfg-and-db-handle($cfg-file is copy) {
    my $cfg = Agrammon::Config.new;
    $cfg-file //= %*ENV<AGRAMMON_CFG> || 'etc/agrammon.cfg.yaml';
    die "Config file $cfg-file not found" unless $cfg-file.IO.e;
    note "Loading config from $cfg-file";
    $cfg.load($cfg-file);
    my $db = DB::Pg.new(conninfo => $cfg.db-conninfo);
    PROCESS::<$AGRAMMON-DB-CONNECTION> = $db;
    return ($cfg, $db);
}

sub web(Str $cfg-file, Str $model-filename, Str $technical-file?) is export {
    # initialization
    my ($model, $model-path, $cfg, $db) = load-model($cfg-file, $model-filename);
    my %technical-parameters = load-technical($model-path.IO.parent, $technical-file);
    my $ws = Agrammon::Web::Service.new(:$cfg, :$model, :%technical-parameters);

    # setup and start web server
    my $host = %*ENV<AGRAMMON_HOST> || '0.0.0.0';
    my $port = %*ENV<AGRAMMON_PORT> || 20000;
    my $application = route {
        # API routes don't need an ongoing session, but do token auth.
        delegate <api v1 *> => api-routes($ws);
        # Everything else gets the standard session mechanism.
        delegate <*> => route {
            before Agrammon::Web::SessionStore.new(:$db);
            delegate <*> => routes($ws);
        }
    }
    my Cro::Service $http = Cro::HTTP::Server.new(
        :$host, :$port, :$application,
        after => [
            Cro::HTTP::Log::File.new(logs => $*OUT, errors => $*ERR)
        ]
    );
    $http.start;
    say "Listening at http://$host:$port";
    return $http;
}

sub preprocessor-options(Str $variants) {
    set($variants.split(","));
}

sub get-input-filehandle(IO::Path $path) {
    $path eq '-' ?? $*IN
                 !! open $path, :r
                        or die "Couldn't open file $path for reading";
}
