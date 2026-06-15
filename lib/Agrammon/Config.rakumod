use v6;
use POFile;
use YAMLish;

class Agrammon::Config {
    has %.general;
    has %.database;
    has %.gui;
    has %.model;
    has @.versions;
    has %.translations;
    has $!base-url;

    method load(Str $path) {
        my $yaml = slurp($path);
        my $config = load-yaml($yaml);

        %!general      = $config<General>;
        %!database     = $config<Database>;
        %!gui          = $config<GUI>;
        %!model        = $config<Model>;
        @!versions     = ($config<Versions> // ()).list;
        %!translations = self!get-translations;
        $!base-url     = $config<GUI><baseUrl>;
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
        }).list;
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
