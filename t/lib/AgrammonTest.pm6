sub prepare-test-db($uid) is export {
    my $db = $*AGRAMMON-DB-HANDLE;

    $db.query(q:to/SQL/);
    CREATE TABLE IF NOT EXISTS role (
        role_id       SERIAL NOT NULL PRIMARY KEY, -- Unique ID
        role_name     TEXT NOT NULL UNIQUE
    )
    SQL

    my $results = $db.query(q:to/SQL/);
    SELECT role_id
      FROM role
    SQL

    my @ids = $results.arrays.sort;
    if not @ids eqv [[0],[1],[2]] {
        my $sth = $db.prepare(q:to/SQL/);
            INSERT INTO role (role_id, role_name)
            VALUES ($1, $2)
        SQL
        $sth.execute(0, 'admin');
        $sth.execute(1, 'user');
        $sth.execute(2, 'support');
    }

    $db.query(q:to/SQL/);
    CREATE TABLE IF NOT EXISTS pers (
        pers_id         SERIAL NOT NULL PRIMARY KEY,             -- Unique ID
        pers_email      TEXT NOT NULL UNIQUE,                    -- used as login name
        pers_first      TEXT NOT NULL CHECK (pers_first != ''),  -- First Name of Person
        pers_last       TEXT NOT NULL CHECK (pers_last != ''),   -- Last Name of Person
        pers_password   TEXT NOT NULL,                           -- Password
        pers_org        TEXT NOT NULL,                           -- Organisation
        pers_last_login TIMESTAMP WITHOUT TIME ZONE,
        pers_created    TIMESTAMP WITHOUT TIME ZONE,
        pers_role       INTEGER NOT NULL REFERENCES role(role_id) DEFAULT 1
    )
    SQL

    $db.query(q:to/SQL/);
    CREATE TABLE IF NOT EXISTS dataset (
        dataset_id       SERIAL NOT NULL PRIMARY KEY,                 -- Unique ID
        dataset_name     TEXT NOT NULL,                               -- dataset name
        dataset_pers     INTEGERT NOT NULL REFERENCES pers(pers_id),  -- owner
        dataset_version  TEXT DEFAULT '2.0',                          -- Version
        dataset_comment  TEXT,
        dataset_model    TEXT,
        dataset_readonly BOOLEAN DEFAULT False
    )
    SQL


    $db.query(q:to/SQL/);
    CREATE TABLE IF NOT EXISTS data_new (
        data_id             SERIAL NOT NULL PRIMARY KEY,
        data_dataset        INTEGER NOT NULL REFERENCES dataset(dataset_id) ON DELETE CASCADE,
        data_var            TEXT NOT NULL,
        data_instance       TEXT,
        data_val            TEXT,
        data_instance_order INTEGER,
        data_comment        TEXT
    )
    SQL

    $db.query(q:to/SQL/);
    CREATE TABLE IF NOT EXISTS branches (
        branches_id      SERIAL NOT NULL PRIMARY KEY,                                            -- Unique ID
        branches_var     INTEGER NOT NULL UNIQUE REFERENCES data_new(data_id) ON DELETE CASCADE, -- branched variables
        branches_data    NUMERIC[],                                                              -- branch fractions
        branches_options TEXT[]                                                                  -- branch options
    )
    SQL

    $db.query(q:to/SQL/);
    INSERT INTO pers (pers_id, pers_email, pers_password)
              VALUES (42000, 'foo@agrammon.ch', 'XXX')
    SQL

    $db.query(q:to/SQL/, $uid);
    INSERT INTO dataset (dataset_id, dataset_name, dataset_pers)
                 VALUES (42000, 'BranchTest', $1)
    SQL

    $db.query(q:to/SQL/);
    INSERT INTO data_new (data_id, data_dataset, data_var, data_instance, data_val)
                 VALUES (76315980, 42000, 'Livestock::Poultry[]::Housing::Type::housing_type',             'Branched', 'branched'),
                        (76315982, 42000, 'Livestock::Poultry[]::Housing::Type::manure_removal_interval',  'Branched', 'branched')
    SQL

    $db.query(q:to/SQL/);
    INSERT INTO branches
         VALUES (30949, 76315980, '{0,0,0,0,0,0,0,15.9,31.5,33.5,0,0,0,0,0,0,0,2.2,0,0,0,0,0,16.9}', '{manure_belt_with_manure_belt_drying_system,manure_belt_without_manure_belt_drying_system,deep_pit,deep_litter}'),
                (30950, 76315982, '{0,0,0,0,0,0,0,15.9,31.5,33.5,0,0,0,0,0,0,0,2.2,0,0,0,0,0,16.9}', '{less_than_twice_a_month,twice_a_month,3_to_4_times_a_month,more_than_4_times_a_month,once_a_day,no_manure_belt}')
    SQL

    return 1;
}

sub transactionally(&test) is export {
    my $*AGRAMMON-DB-HANDLE = my $db = $*AGRAMMON-DB-CONNECTION.db;
    $db.begin;
    test($db);
    $db.finish;
}
