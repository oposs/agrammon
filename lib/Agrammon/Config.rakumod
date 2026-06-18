use v6;
use POFile;
use YAMLish;
use Agrammon::JSONSchema;

class X::Agrammon::Config::Invalid is Exception {
    has $.file;
    has @.problems;
    method message() {
        "Invalid configuration in $!file:\n" ~ @!problems.map('  - ' ~ *).join("\n");
    }
}

class Agrammon::Config {
    has %.general;
    has %.database;
    has %.gui;
    has %.model;
    has @.versions;
    has %.translations;
    has $!base-url;

    # Required entries and value types for the config file, checked at load
    # time so a missing or mistyped key fails fast with a clear message instead
    # of detonating cryptically later (issue #296). Every key a deployment may
    # legitimately use must be listed; `additionalProperties: False` makes an
    # unknown key (e.g. a typo, or a dropped legacy key) an error. Required
    # string values use `minLength: 1` so they cannot be blank.
    my %REQ-STR = type => 'string', minLength => 1;
    my %CONFIG-SCHEMA =
        type => 'object',
        required => <General Database GUI Model>.List,
        additionalProperties => False,
        properties => {
            General => {
                type => 'object',
                required => <translationDir>.List,
                additionalProperties => False,
                properties => {
                    translationDir => %REQ-STR,
                    debugLevel     => { type => 'integer' },
                    log_file       => { type => 'string' },
                    log_level      => { type => 'string' },
                    tmpDir         => { type => 'string' },
                    typst          => { type => 'string' },
                    ghostscript    => { type => 'string' },
                    pdfTimeout     => { type => 'integer' },
                    taxonomy       => { type => 'string' },
                },
            },
            Database => {
                type => 'object',
                required => <name host user password>.List,
                additionalProperties => False,
                properties => {
                    name     => %REQ-STR,
                    host     => %REQ-STR,
                    user     => %REQ-STR,
                    password => { type => 'string' },
                    port     => { type => 'integer' },
                },
            },
            GUI => {
                type => 'object',
                required => <baseUrl variant title>.List,
                additionalProperties => False,
                properties => {
                    baseUrl    => %REQ-STR,
                    variant    => %REQ-STR,
                    title      => { type => 'object', minProperties => 1 },
                    version    => { type => 'string' },
                    submission => { },
                },
            },
            Model => {
                type => 'object',
                required => <path top variant version>.List,
                additionalProperties => False,
                properties => {
                    path               => %REQ-STR,
                    top                => %REQ-STR,
                    variant            => %REQ-STR,
                    version            => %REQ-STR,
                    technical          => { type => 'string' },
                    debugLevel         => { type => 'integer' },
                    versions           => { type => 'array' },
                    compatibleVersions => { type => 'array' },
                },
            },
            Versions => { type => 'array' },
        };

    method load(Str $path) {
        my $yaml = slurp($path);
        my $config = load-yaml($yaml);

        self!validate-config($config, $path);

        %!general      = $config<General>;
        %!database     = $config<Database>;
        %!gui          = $config<GUI>;
        %!model        = $config<Model>;
        @!versions     = ($config<Versions> // ()).list;
        %!translations = self!get-translations;
        $!base-url     = $config<GUI><baseUrl>;
    }

    method !validate-config($config, $file) {
        my @problems = Agrammon::JSONSchema.new(schema => %CONFIG-SCHEMA)
            .validate-errors($config)
            .map({ self!render-problem($_, $config) })
            .unique;   # one `additionalProperties` failure per unknown key collapses to one message
        die X::Agrammon::Config::Invalid.new(:$file, :@problems) if @problems;
    }

    # Turn a JSON-Schema failure into a config-oriented message: drop the
    # `root`/`properties` noise, and for an unknown-key (`additionalProperties`)
    # failure name the offending key(s) by diffing against the declared ones.
    method !render-problem($problem, $config) {
        my @seg = $problem.path.split('/').grep({ $_ ne 'root' && $_ ne 'properties' });
        if @seg && @seg.tail eq 'additionalProperties' {
            my @ctx      = @seg[0 ..^ *-1];
            my %declared = @ctx ?? (%CONFIG-SCHEMA<properties>{@ctx[0]}<properties> // %())
                                !! %CONFIG-SCHEMA<properties>;
            my %actual   = @ctx ?? ($config{@ctx[0]} // %()) !! $config;
            my @unknown  = (%actual.keys (-) %declared.keys).keys.sort;
            my $where    = @ctx ?? @ctx[0] !! 'top level';
            return "unknown key{ @unknown == 1 ?? '' !! 's' } "
                 ~ @unknown.map({ "'$_'" }).join(', ') ~ " in $where";
        }
        my $where  = @seg.join('.') || 'config';
        my $reason = $problem.reason.subst('String has less than 1 codepoints', 'must not be empty');
        return "$where: $reason";
    }

    method model-path {
        %!model<path>
    }

    method gui-url {
        $!base-url;
    }

    method gui-variant {
        %!gui<variant>;
    }

    # The GUI title hash ({de,en,fr,...}). Any `%VERSION%` placeholder is
    # replaced with $version (the deployment's model version by default), so a
    # config can carry one templated title instead of a hardcoded version.
    # Legacy titles with the version baked in have no placeholder -> no-op.
    method gui-title($version = self.model-version) {
        my $v = $version // '';
        %( %!gui<title>.map({ .key => .value.subst('%VERSION%', $v, :g) }) );
    }

    # The Versions switcher entries with any `%VERSION%` in each entry's title
    # resolved to that entry's own version. Other fields pass through.
    method versions-resolved {
        @!versions.map(-> $v {
            $v ~~ Associative && $v<title>
                ?? %( |$v, title => %( $v<title>.map({ .key => .value.subst('%VERSION%', ~($v<version> // ''), :g) }) ) )
                !! $v
        }).Array;
    }

    # User-visible short version label (e.g. '7.0'). Distinct from
    # Model.version (internal identifier). Optional; falls through to
    # Model.version when not set so existing deployments keep working.
    method gui-version {
        %!gui<version> // %!model<version>;
    }

    method model-variant {
        %!model<variant>;
    }

    method model-top {
        %!model<top>;
    }

    method model-version {
        %!model<version>;
    }

    # Other Model.version strings this deployment accepts as data-
    # compatible: datasets tagged with any of these will be claimed
    # (promoted to Model.version) on first open. Empty list = strict
    # mode (only the deployment's own dataset rows are openable).
    method model-compatible-versions {
        (%!model<compatibleVersions> // ()).list;
    }

    method agrammon-variant {
        # `version` tags rows written to `dataset.dataset_version`. Sourced
        # from Model.version (the same identifier the frontend compares
        # against in the version switcher), so that dataset table rows
        # written by this deployment are recognized as belonging to it.
        # Was Database.version historically — see CHANGELOG.
        %(
            version             => %!model<version>,
            gui                 => %!gui<variant>,
            model               => %!model<variant>,
            compatible-versions => self.model-compatible-versions,
        );
    }

    method db-conninfo {
        return 'dbname='   ~ %!database<name> ~ ' '
             ~ 'host='     ~ %!database<host> ~ ' '
             ~ 'port='     ~ (%!database<port> // '5432') ~ ' '
             ~ 'user='     ~ %!database<user> ~ ' '
             ~ 'password=' ~ %!database<password>;
    }

    method submission {
        %!gui<submission>
    }

    method !get-translations {
        my @files = %!general<translationDir>.IO.dir.grep(*.extension eq 'po');
        my %lx;
        for @files -> $file {
            $file ~~ / $<locale> = [.+]\.po $/;
            my $locale = $file.basename.subst(/'.po'$/, '');
            my $lang = $locale.subst(/_.+/, '');
            my $po = POFile.load($file);
            for @$po -> POFile::Entry $entry {
                with $entry.msgid -> $id {
                    %lx{$lang}{$id} = $entry.msgstr;
                }
            }
        }
        return %lx;
    }

}
