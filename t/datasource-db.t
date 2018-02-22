use v6;
use Agrammon::DataSource::DB;
use DBIish;
use Sys::Hostname;
use Test;

my $host = hostname;
my $db-host = 'localhost';
my $db-user = 'postgres';
my $password;
if ($host eq 'engelberg') {
    my $pg-file = $*PROGRAM.parent.add('test-data/.secret/agrammon.pg');
    if ($pg-file.IO.e) {
        my @pg-data = $pg-file.IO.lines;
        if (@pg-data) {
            $db-host  = chomp @pg-data[0];
            $db-user  = chomp @pg-data[1];
            $password = chomp @pg-data[2];
        }
    }
}

my $username = 'fritz.zaucker@oetiker.ch';
my $dataset  = 'Agrammon6Testing';

my $dbh = DBIish.connect('Pg',
                         host => $db-host,
                         :port(5432),
                         :database<agrammon_dev>,
                         user => $db-user,
                         :$password
                        );

if ($host ne 'engelberg') {
    ok prepare-test-db($dbh, $dataset), 'Test database prepared';
}

my $rowsExpected = 6;

my $ds = Agrammon::DataSource::DB.new;
isa-ok $ds, Agrammon::DataSource::DB, 'Is a DataSource::DB';

my @data = $ds.read($dbh, $username, $dataset);
is @data.elems, $rowsExpected, "Found $rowsExpected rows in dataset $username:$dataset";

$dbh.dispose;

done-testing;



sub prepare-test-db($dbh, $dataset) {
    my $sth = $dbh.do(q:to/STATEMENT/);
    CREATE TABLE pers (
        pers_id       SERIAL NOT NULL PRIMARY KEY,             -- Unique ID
        pers_email    TEXT NOT NULL UNIQUE,                       -- used as login name
        pers_first    TEXT NOT NULL CHECK (pers_first != ''),  -- First Name of Person
        pers_last     TEXT NOT NULL CHECK (pers_last != ''),   -- Last Name of Person
        pers_password TEXT NOT NULL                               -- Password for pers data
    )
    STATEMENT

    $sth = $dbh.do(q:to/STATEMENT/);
    INSERT INTO pers (pers_id, pers_email, pers_first, pers_last, pers_password)
         VALUES (1, 'fritz.zaucker@oetiker.ch', 'Fritz', 'Zaucker', 'test')
    STATEMENT

    $sth = $dbh.do(q:to/STATEMENT/);
    CREATE TABLE dataset (
        dataset_id      SERIAL NOT NULL PRIMARY KEY,             -- Unique ID
        dataset_name  TEXT NOT NULL,                             -- User selected name
        dataset_pers  INT4 REFERENCES pers NOT NULL,             -- Owner of data
        dataset_mod_date TIMESTAMP,                              -- last changed
        UNIQUE(dataset_name, dataset_pers)
    )
    STATEMENT

    $sth = $dbh.prepare(q:to/STATEMENT/);
    INSERT INTO dataset (dataset_name, dataset_pers)
    VALUES (?, ?);
    STATEMENT
    $sth.execute($dataset, 1);

    $sth = $dbh.do(q:to/STATEMENT/);
    CREATE TABLE data_new (
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
    CREATE TABLE branches (
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
    CREATE FUNCTION dataset_name2id(USERNAME text, NAME text) returns int4
       AS 'SELECT dataset_id FROM dataset WHERE dataset_name = $2 AND dataset_pers = pers_email2id($1)' STABLE LANGUAGE 'sql'
    STATEMENT

    $sth = $dbh.prepare(q:to/STATEMENT/);
    SELECT dataset_name2id(?, ?)
    STATEMENT
    $sth.execute($username, $dataset);
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
