use v6;
use YAMLish;

class Agrammon::Config {
    has %.general;
    has %.database;
    has %.gui;
    has %.model;
  
    method load(Str $path) {
        my $yaml = slurp($path);
        my $config = load-yaml($yaml);

        %!general  = $config<General>;
        %!database = $config<Database>;
        %!gui      = $config<GUI>;
        %!model    = $config<Model>;
    }

    method gui-variant {
        %!gui<variant> ;
    }

    method model-variant {
        %!model<variant>;
    }

    method app-variant {
        %!gui<variant> ~ %!model<variant>;
    }

    method db-conninfo {
        return 'dbname='   ~ %!database<name> ~ ' '
             ~ 'host='     ~ %!database<host> ~ ' '
             ~ 'user='     ~ %!database<user> ~ ' '
             ~ 'password=' ~ %!database<password>;
    }

}
