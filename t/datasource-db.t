use v6;
use Agrammon::DataSource::DB;
use DB::Pg;
use Test;

plan 37;

if %*ENV<AGRAMMON_UNIT_TEST> {
    skip-rest 'Not a unit test';
    exit;
}

my $db-host     = 'localhost';
my $db-port     = '5432';
my $db-user     = 'postgres';
my $db-database = 'agrammon_test';
my $db-password = '';
my $ag-user     = 'test@agrammon.ch';
my $ag-dataset  = 'Agrammon6Testing';

# overwrite defaults $db-* and $ag-* variables above
# Format auf agrammon.pg:
# dbhost=HOST;dbport=PORT;dbuser=USER;dbpassword=PASSWORD;dbdatabase=DATABASE;aguser=AGUSER;agdataset=DATASET;
# All in one line, each key=value pair terminated with ;
# Fields missing are either set to '' (port, password) or stay as above
my $pg-file = $*PROGRAM.parent.add('test-data/.secret/agrammon.pg');
if $pg-file.IO.e {
    my $pg-data = chomp slurp($pg-file);

    if $pg-data ~~ /dbhost '=' (.+?) ';'/ {
        $db-host = $/[0];
    }
    $db-port = $pg-data ~~ /dbport '=' (.+?) ';'/ ?? $/[0] !! '';

    if $pg-data ~~ /dbuser '=' (.+?) ';'/ {
        $db-user = $/[0];
    }
    $db-password = $pg-data ~~ /dbpassword '=' (.+?) ';'/ ?? $/[0] !! '';
    if $pg-data ~~ /dbdatabase '=' (.+?) ';'/ {
        $db-database = $/[0];
    }

    if $pg-data ~~ /aguser '=' (.+?) ';'/ {
        $ag-user = $/[0];
    }
    if $pg-data ~~ /agdataset '=' (.+?) ';'/ {
        $ag-dataset = ~$0; # force to string
    }
#    diag "dbhost=$db-host, dbport=$db-port, dbuser=$db-user, dbpassword=$db-password, dbdatabase=$db-database";
    diag "dbhost=$db-host, dbport=$db-port, dbuser=$db-user, dbpassword=XXX, dbdatabase=$db-database";
    diag "ag-user=$ag-user, ag-dataset=$ag-dataset";
}

my $conninfo;
if %*ENV<GITHUB_ACTIONS> {
    my $db-user     = 'postgres';
    my $db-password = 'postgres';
    my $db-database = 'agrammon_test';
    my $db-host     = 'localhost';
    
    $conninfo = "host=$db-host user=$db-user dbname=$db-database password=$db-password port=%*ENV<POSTGRES_PORT>";
}
else {
     $conninfo = "host=$db-host user=$db-user password=$db-password dbname=$db-database";
}
ok my $*AGRAMMON-DB-CONNECTION = DB::Pg.new(:$conninfo), 'Create DB::Pg object';

transactionally {
    lives-ok { prepare-test-db-single-data($ag-user, $ag-dataset) }, 'Test database prepared';

    my $ds = Agrammon::DataSource::DB.new;
    isa-ok $ds, Agrammon::DataSource::DB, 'Is a DataSource::DB';

    ### TODO: check actual data
    my $dataset = $ds.read($ag-user, $ag-dataset, {});
    isa-ok $dataset, Agrammon::Inputs, 'Correct type';
    is $dataset.simulation-name, 'DB', 'Correct simulation name';
    is $dataset.dataset-id, $ag-dataset, 'Correct data set ID';
}

transactionally {
    lives-ok { prepare-test-db-flattened-data($ag-user, $ag-dataset) }, 'Flattened test database prepared';

    my $ds = Agrammon::DataSource::DB.new;
    my $dataset = $ds.read($ag-user, $ag-dataset, { 'Test::Base' => 'Test::Base::Sub::dist-me' });
    isa-ok $dataset, Agrammon::Inputs, 'Correct type';
    is $dataset.simulation-name, 'DB', 'Correct simulation name';
    is $dataset.dataset-id, $ag-dataset, 'Correct data set ID';

    my @instances = $dataset.inputs-list-for('Test::Base');
    is @instances.elems, 3, 'Produced 3 instances from the distribution loaded from DB';
    @instances .= sort(*.input-hash-for('Test::Base::AnotherSub').<flat-a>);
    is-deeply @instances[0].input-hash-for('Test::Base::Sub'),
            { dist-me => 300, simple => 42 }, 'Correct distribution value for first flattened input';
    is-deeply @instances[0].input-hash-for('Test::Base::AnotherSub'),
            { flat-a => 'x', simple => 101 }, 'Correct enum value for first flattened input';
    is-deeply @instances[0].input-hash-for('Test::Base::Retained'),
            { simple => 13 }, 'Non-distributed instance data was correctly loaded';
    is-deeply @instances[1].input-hash-for('Test::Base::Sub'),
            { dist-me => 200, simple => 42 }, 'Correct distribution value for second flattened input';
    is-deeply @instances[1].input-hash-for('Test::Base::AnotherSub'),
            { flat-a => 'y', simple => 101 }, 'Correct enum value for second flattened input';
    is-deeply @instances[1].input-hash-for('Test::Base::Retained'),
            { simple => 13 }, 'Non-distributed instance data was correctly loaded';
    is-deeply @instances[2].input-hash-for('Test::Base::Sub'),
            { dist-me => 500, simple => 42 }, 'Correct distribution value for third flattened input';
    is-deeply @instances[2].input-hash-for('Test::Base::AnotherSub'),
            { flat-a => 'z', simple => 101 }, 'Correct enum value for third flattened input';
    is-deeply @instances[2].input-hash-for('Test::Base::Retained'),
            { simple => 13 }, 'Non-distributed instance data was correctly loaded';
}

transactionally {
    lives-ok { prepare-test-db-branched-data($ag-user, $ag-dataset) }, 'Branched test database prepared';

    my $ds = Agrammon::DataSource::DB.new;
    my $dataset = $ds.read($ag-user, $ag-dataset, { 'Test::Base' => 'Test::Base::Sub::dist-me' });
    isa-ok $dataset, Agrammon::Inputs, 'Correct type';
    is $dataset.simulation-name, 'DB', 'Correct simulation name';
    is $dataset.dataset-id, $ag-dataset, 'Correct data set ID';

    my @instances = $dataset.inputs-list-for('Test::Base');
    is @instances.elems, 6, 'Produced 6 instances from the distribution loaded from DB';
    @instances .= sort({ .<flat-b>, .<flat-a> given .input-hash-for('Test::Base::AnotherSub') });
    is-deeply @instances[0].input-hash-for('Test::Base::Sub'),
            { dist-me => 120, simple => 42 }, 'Correct distribution value for first branched input';
    is-deeply @instances[0].input-hash-for('Test::Base::AnotherSub'),
            { flat-a => 'x', flat-b => 'a', simple => 101 }, 'Correct enum value for first branched input';
    is-deeply @instances[1].input-hash-for('Test::Base::Sub'),
            { dist-me => 80, simple => 42 }, 'Correct distribution value for second branched input';
    is-deeply @instances[1].input-hash-for('Test::Base::AnotherSub'),
            { flat-a => 'y', flat-b => 'a', simple => 101 }, 'Correct enum value for second branched input';
    is-deeply @instances[2].input-hash-for('Test::Base::Sub'),
            { dist-me => 200, simple => 42 }, 'Correct distribution value for third branched input';
    is-deeply @instances[2].input-hash-for('Test::Base::AnotherSub'),
            { flat-a => 'z', flat-b => 'a', simple => 101 }, 'Correct enum value for third branched input';
    is-deeply @instances[3].input-hash-for('Test::Base::Sub'),
            { dist-me => 180, simple => 42 }, 'Correct distribution value for fourth branched input';
    is-deeply @instances[3].input-hash-for('Test::Base::AnotherSub'),
            { flat-a => 'x', flat-b => 'b', simple => 101 }, 'Correct enum value for fourth branched input';
    is-deeply @instances[4].input-hash-for('Test::Base::Sub'),
            { dist-me => 120, simple => 42 }, 'Correct distribution value for fifth branched input';
    is-deeply @instances[4].input-hash-for('Test::Base::AnotherSub'),
            { flat-a => 'y', flat-b => 'b', simple => 101 }, 'Correct enum value for fifth branched input';
    is-deeply @instances[5].input-hash-for('Test::Base::Sub'),
            { dist-me => 300, simple => 42 }, 'Correct distribution value for sixth branched input';
    is-deeply @instances[5].input-hash-for('Test::Base::AnotherSub'),
            { flat-a => 'z', flat-b => 'b', simple => 101 }, 'Correct enum value for sixth branched input';
};

sub prepare-test-db-single-data($user, $dataset) {
    my $db = $*AGRAMMON-DB-HANDLE;

    prepare-test-db-schema($db, $user);

    my $userId = $db.query(q:to/STATEMENT/, $user).value;
    SELECT pers_email2id($1)
    STATEMENT

    $db.query(q:to/STATEMENT/, $dataset, $userId);
    INSERT INTO dataset (dataset_name, dataset_pers)
    VALUES ($1, $2);
    STATEMENT

    my $datasetId = $db.query(q:to/STATEMENT/, $user, $dataset).value;
    SELECT dataset_name2id($1, $2)
    STATEMENT

    my $sth = $db.prepare(q:to/STATEMENT/);
    INSERT INTO data_new (data_dataset, data_var, data_val)
    VALUES ($1, $2, $3)
    STATEMENT

    $sth.execute($datasetId, 'PlantProduction::AgriculturalArea::agricultural_area', 22);
    $sth.execute($datasetId, 'PlantProduction::MineralFertiliser::mineral_nitrogen_fertiliser_urea', 0);
    $sth.execute($datasetId, 'PlantProduction::MineralFertiliser::mineral_nitrogen_fertiliser_except_urea', 400);
    $sth.execute($datasetId, 'PlantProduction::RecyclingFertiliser::compost', 0);
    $sth.execute($datasetId, 'PlantProduction::RecyclingFertiliser::solid_digestate', 0);
    $sth.execute($datasetId, 'PlantProduction::RecyclingFertiliser::liquid_digestate', 0);
}

sub prepare-test-db-flattened-data($user, $dataset) {
    my $db = $*AGRAMMON-DB-HANDLE;

    prepare-test-db-schema($db, $user);

    my $userId = $db.query(q:to/STATEMENT/, $user).value;
    SELECT pers_email2id($1)
    STATEMENT

    $db.query(q:to/STATEMENT/, $dataset, $userId);
    INSERT INTO dataset (dataset_name, dataset_pers)
    VALUES ($1, $2);
    STATEMENT

    my $datasetId = $db.query(q:to/STATEMENT/, $user, $dataset).value;
    SELECT dataset_name2id($1, $2)
    STATEMENT

    my $sth = $db.prepare(q:to/STATEMENT/);
    INSERT INTO data_new (data_dataset, data_instance, data_var, data_val)
    VALUES ($1, $2, $3, $4)
    STATEMENT

    $sth.execute($datasetId, 'Instance A', 'Test::Base[]::Sub::dist-me', 1000);
    $sth.execute($datasetId, 'Instance A', 'Test::Base[]::Sub::simple', 42);
    $sth.execute($datasetId, 'Instance A', 'Test::Base[]::AnotherSub::flat-a', 'flattened');
    $sth.execute($datasetId, 'Instance A', 'Test::Base[]::AnotherSub::flat-a_flattened00_x', 30);
    $sth.execute($datasetId, 'Instance A', 'Test::Base[]::AnotherSub::flat-a_flattened01_y', 20);
    $sth.execute($datasetId, 'Instance A', 'Test::Base[]::AnotherSub::flat-a_flattened02_z', 50);
    $sth.execute($datasetId, 'Instance A', 'Test::Base[]::AnotherSub::simple', 101);
    $sth.execute($datasetId, 'Instance A', 'Test::Base[]::Retained::simple', 13);
}

sub prepare-test-db-branched-data($user, $dataset) {
    my $db = $*AGRAMMON-DB-HANDLE;

    prepare-test-db-schema($db, $user);

    my $userId = $db.query(q:to/STATEMENT/, $user).value;
    SELECT pers_email2id($1)
    STATEMENT

    $db.query(q:to/STATEMENT/, $dataset, $userId);
    INSERT INTO dataset (dataset_name, dataset_pers)
    VALUES ($1, $2);
    STATEMENT

    my $datasetId = $db.query(q:to/STATEMENT/, $user, $dataset).value;
    SELECT dataset_name2id($1, $2)
    STATEMENT

    my $sth-data = $db.prepare(q:to/STATEMENT/);
    INSERT INTO data_new (data_dataset, data_instance, data_var, data_val)
    VALUES ($1, $2, $3, $4)
    RETURNING data_id;
    STATEMENT

    my $sth-branch = $db.prepare(q:to/STATEMENT/);
    INSERT INTO branches (branches_var, branches_data, branches_options)
    VALUES ($1, $2, $3)
    STATEMENT

    $sth-data.execute($datasetId, 'Instance A', 'Test::Base[]::Sub::dist-me', 1000);
    $sth-data.execute($datasetId, 'Instance A', 'Test::Base[]::Sub::simple', 42);
    given $sth-data.execute($datasetId, 'Instance A', 'Test::Base[]::AnotherSub::flat-a', 'branched').value -> $id {
        $sth-branch.execute($id, '{12,18,8,12,20,30}', '{x,y,z}');
    };
    given $sth-data.execute($datasetId, 'Instance A', 'Test::Base[]::AnotherSub::flat-b', 'branched').value -> $id {
        $sth-branch.execute($id, '{12,18,8,12,20,30}', '{a,b}');
    };
    $sth-data.execute($datasetId, 'Instance A', 'Test::Base[]::AnotherSub::simple', 101);
}

sub prepare-test-db-schema($db, $user) {
    $db.query(q:to/STATEMENT/);
    CREATE TABLE IF NOT EXISTS pers (
        pers_id       SERIAL NOT NULL PRIMARY KEY,             -- Unique ID
        pers_email    TEXT NOT NULL UNIQUE,                    -- used as login name
        pers_first    TEXT NOT NULL CHECK (pers_first != ''),  -- First Name of Person
        pers_last     TEXT NOT NULL CHECK (pers_last != ''),   -- Last Name of Person
        pers_password TEXT NOT NULL                               -- Password for pers data
    )
    STATEMENT

    $db.query(q:to/STATEMENT/);
    CREATE TABLE IF NOT EXISTS dataset (
        dataset_id      SERIAL NOT NULL PRIMARY KEY,             -- Unique ID
        dataset_name  TEXT NOT NULL,                             -- User selected name
        dataset_pers  INT4 REFERENCES pers NOT NULL,             -- Owner of data
        dataset_mod_date TIMESTAMP,                              -- last changed
        UNIQUE(dataset_name, dataset_pers)
    )
    STATEMENT

    $db.query(q:to/STATEMENT/);
    CREATE TABLE IF NOT EXISTS data_new (
        data_id SERIAL NOT NULL PRIMARY KEY,             -- Unique ID
        data_dataset  INT4 REFERENCES dataset NOT NULL,
        data_var        TEXT NOT NULL,                           -- Agrammon variable name
        data_instance TEXT,
        data_val        TEXT,                                    -- Value of Agrammon variable
        data_instance_order integer,
        data_comment  TEXT
    )                
    STATEMENT

    $db.query(q:to/STATEMENT/);
    CREATE TABLE IF NOT EXISTS branches (
        branches_id   SERIAL NOT NULL PRIMARY KEY,       -- Unique ID
        branches_var  INT4 UNIQUE NOT NULL REFERENCES data_new(data_id) ON DELETE CASCADE, -- variable this data belongs to
        branches_data NUMERIC[],
        branches_options TEXT[]
    )
    STATEMENT

    $db.query(q:to/STATEMENT/);
    CREATE OR REPLACE FUNCTION pers_email2id(NAME text) returns int4
       AS 'SELECT pers_id FROM pers WHERE pers_email = $1 ' STABLE LANGUAGE 'sql';
    STATEMENT

    $db.query(q:to/STATEMENT/);
    CREATE OR REPLACE FUNCTION dataset_name2id(USERNAME text, NAME text) returns int4
       AS 'SELECT dataset_id FROM dataset WHERE dataset_name = $2 AND dataset_pers = pers_email2id($1)' STABLE LANGUAGE 'sql'
    STATEMENT

    $db.query(q:to/STATEMENT/, $user);
    INSERT INTO pers (pers_email, pers_first, pers_last, pers_password)
         VALUES ($1, 'X', 'X', 'X')
    STATEMENT
}


sub transactionally(&test) {
    my $*AGRAMMON-DB-HANDLE = my $db = $*AGRAMMON-DB-CONNECTION.db;
    $db.begin;
    test($db);
    $db.finish;
}

