use v6;
use Agrammon::DataSource::DB;
use DBIish;
use Test;

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
if ($pg-file.IO.e) {
    my $pg-data = chomp slurp($pg-file);

    if ($pg-data ~~ /dbhost '=' (.+?) ';'/) {
        $db-host = $/[0];
    }
    $db-port = $pg-data ~~ /dbport '=' (.+?) ';'/ ?? $/[0] !! '';

    if ($pg-data ~~ /dbuser '=' (.+?) ';'/) {
        $db-user = $/[0];
    }
    $db-password = $pg-data ~~ /dbpassword '=' (.+?) ';'/ ?? $/[0] !! '';
    if ($pg-data ~~ /dbdatabase '=' (.+?) ';'/) {
        $db-database = $/[0];
    }

    if ($pg-data ~~ /aguser '=' (.+?) ';'/) {
        $ag-user = $/[0];
    }
    if ($pg-data ~~ /agdataset '=' (.+?) ';'/) {
        $ag-dataset = $/[0];
    }
#    diag "dbhost=$db-host, dbport=$db-port, dbuser=$db-user, dbpassword=$db-password, dbdatabase=$db-database";
    diag "dbhost=$db-host, dbport=$db-port, dbuser=$db-user, dbpassword=XXX, dbdatabase=$db-database";
    diag "aguser=$ag-user, agdataset=$ag-dataset";
}
my $dbh = DBIish.connect('Pg',
                         :host($db-host),
                         :port($db-port),
                         :database($db-database),
                         :user($db-user),
                         :password($db-password)
                        );

my $sth = $dbh.do(q:to/STATEMENT/);
    BEGIN
    STATEMENT

ok prepare-test-db($dbh, $ag-user, $ag-dataset), 'Test database prepared';

my $rowsExpected = 6;

my $ds = Agrammon::DataSource::DB.new;
isa-ok $ds, Agrammon::DataSource::DB, 'Is a DataSource::DB';

my @data = $ds.read($dbh, $ag-user, $ag-dataset);
is @data.elems, $rowsExpected, "Found $rowsExpected rows in dataset $ag-user:$ag-dataset";

$sth = $dbh.do(q:to/STATEMENT/);
    ROLLBACK
    STATEMENT

$dbh.dispose;

done-testing;



sub prepare-test-db($dbh, $user, $dataset) {
    my $sth = $dbh.do(q:to/STATEMENT/);
    CREATE TABLE IF NOT EXISTS pers (
        pers_id       SERIAL NOT NULL PRIMARY KEY,             -- Unique ID
        pers_email    TEXT NOT NULL UNIQUE,                    -- used as login name
        pers_first    TEXT NOT NULL CHECK (pers_first != ''),  -- First Name of Person
        pers_last     TEXT NOT NULL CHECK (pers_last != ''),   -- Last Name of Person
        pers_password TEXT NOT NULL                               -- Password for pers data
    )
    STATEMENT

    $sth = $dbh.do(q:to/STATEMENT/);
    CREATE TABLE IF NOT EXISTS dataset (
        dataset_id      SERIAL NOT NULL PRIMARY KEY,             -- Unique ID
        dataset_name  TEXT NOT NULL,                             -- User selected name
        dataset_pers  INT4 REFERENCES pers NOT NULL,             -- Owner of data
        dataset_mod_date TIMESTAMP,                              -- last changed
        UNIQUE(dataset_name, dataset_pers)
    )
    STATEMENT

    $sth = $dbh.do(q:to/STATEMENT/);
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

    $sth = $dbh.do(q:to/STATEMENT/);
    CREATE TABLE IF NOT EXISTS branches (
        branches_id   SERIAL NOT NULL PRIMARY KEY,       -- Unique ID
        branches_var  INT4 UNIQUE NOT NULL REFERENCES data_new(data_id) ON DELETE CASCADE, -- variable this data belongs to
        branches_data NUMERIC[],
        branches_options TEXT[]
    )
    STATEMENT

    $sth = $dbh.do(q:to/STATEMENT/);
    CREATE OR REPLACE FUNCTION pers_email2id(NAME text) returns int4
       AS 'SELECT pers_id FROM pers WHERE pers_email = $1 ' STABLE LANGUAGE 'sql';
    STATEMENT

    $sth = $dbh.do(q:to/STATEMENT/);
    CREATE OR REPLACE FUNCTION dataset_name2id(USERNAME text, NAME text) returns int4
       AS 'SELECT dataset_id FROM dataset WHERE dataset_name = $2 AND dataset_pers = pers_email2id($1)' STABLE LANGUAGE 'sql'
    STATEMENT

    $sth = $dbh.prepare(q:to/STATEMENT/);
    INSERT INTO pers (pers_email, pers_first, pers_last, pers_password)
         VALUES (?, 'X', 'X', 'X')
    STATEMENT
    $sth.execute($user);

    $sth = $dbh.prepare(q:to/STATEMENT/);
    SELECT pers_email2id(?)
    STATEMENT
    $sth.execute($user);
    my $userId = $sth.row()[0];

    $sth = $dbh.prepare(q:to/STATEMENT/);
    INSERT INTO dataset (dataset_name, dataset_pers)
    VALUES (?, ?);
    STATEMENT
    $sth.execute($dataset, $userId);

    $sth = $dbh.prepare(q:to/STATEMENT/);
    SELECT dataset_name2id(?, ?)
    STATEMENT
    $sth.execute($user, $dataset);
    my $datasetId = $sth.row()[0];
    
    $sth = $dbh.prepare(q:to/STATEMENT/);
        INSERT INTO data_new (data_dataset, data_var, data_val)
        VALUES (?, ?, ?)
    STATEMENT

    $sth.execute($datasetId, 'PlantProduction::AgriculturalArea::agricultural_area', 22);
    $sth.execute($datasetId, 'PlantProduction::MineralFertiliser::mineral_nitrogen_fertiliser_urea', 0);
    $sth.execute($datasetId, 'PlantProduction::MineralFertiliser::mineral_nitrogen_fertiliser_except_urea', 400);
    $sth.execute($datasetId, 'PlantProduction::RecyclingFertiliser::compost', 0);
    $sth.execute($datasetId, 'PlantProduction::RecyclingFertiliser::solid_digestate', 0);
    $sth.execute($datasetId, 'PlantProduction::RecyclingFertiliser::liquid_digestate', 0);
    $sth.finish;
    return 1;
}
