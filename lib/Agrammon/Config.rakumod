use v6;
use POFile;
use YAMLish;

class Agrammon::Config {
    has %.general;
    has %.database;
    has %.gui;
    has %.model;
    has %.translations;
    has $!base-url;

    method load(Str $path) {
        my $yaml = slurp($path);
        my $config = load-yaml($yaml);

        %!general      = $config<General>;
        %!database     = $config<Database>;
        %!gui          = $config<GUI>;
        %!model        = $config<Model>;
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

    method gui-title {
        %!gui<title>;
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

    method agrammon-variant {
        %(
            version => %!database<version>,
            gui     => %!gui<variant>,
            model   => %!model<variant>,
        );
    }

    method db-conninfo {
        return 'dbname='   ~ %!database<name> ~ ' '
             ~ 'host='     ~ %!database<host> ~ ' '
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
