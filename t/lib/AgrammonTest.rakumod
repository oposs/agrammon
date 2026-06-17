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
        dataset_pers     INTEGER NOT NULL REFERENCES pers(pers_id),  -- owner
        dataset_version  TEXT NOT NULL DEFAULT '6.0',
        dataset_guivariant TEXT NOT NULL,
        dataset_modelvariant TEXT NOT NULL,
        dataset_comment  TEXT,
        dataset_readonly BOOLEAN DEFAULT False,
        dataset_created TIMESTAMP DEFAULT now(),
        dataset_mod_date TIMESTAMP DEFAULT now()
    )
    SQL


    $db.query(q:to/SQL/);
    CREATE TABLE IF NOT EXISTS data_instance (
        data_instance_id      SERIAL NOT NULL PRIMARY KEY,
        data_instance_dataset INTEGER NOT NULL REFERENCES dataset(dataset_id) ON DELETE CASCADE,
        data_instance_name    TEXT NOT NULL,
        data_instance_order   INTEGER,
        UNIQUE (data_instance_dataset, data_instance_name)
    )
    SQL

    $db.query(q:to/SQL/);
    CREATE TABLE IF NOT EXISTS data (
        data_id          SERIAL NOT NULL PRIMARY KEY,
        data_dataset     INTEGER NOT NULL REFERENCES dataset(dataset_id) ON DELETE CASCADE,
        data_var         TEXT NOT NULL,
        data_val         TEXT,
        data_instance_id INTEGER REFERENCES data_instance(data_instance_id) ON DELETE CASCADE,
        data_comment     TEXT,
        UNIQUE (data_var, data_instance_id, data_dataset)
    )
    SQL

    $db.query(q:to/SQL/);
    CREATE TABLE IF NOT EXISTS branches (
        branches_id          SERIAL NOT NULL PRIMARY KEY,                                             -- Unique ID
        branches_row_var     INTEGER NOT NULL UNIQUE REFERENCES data(data_id) ON DELETE CASCADE,      -- row-axis branched variable
        branches_col_var     INTEGER NOT NULL UNIQUE REFERENCES data(data_id) ON DELETE CASCADE,      -- col-axis branched variable
        branches_row_options TEXT[]    NOT NULL,                                                      -- row-axis option labels
        branches_col_options TEXT[]    NOT NULL,                                                      -- col-axis option labels
        branches_matrix      NUMERIC[] NOT NULL,                                                      -- 2-D fraction matrix (rows x cols)
        CHECK (array_ndims(branches_matrix) = 2),
        CHECK (array_length(branches_matrix, 1) = cardinality(branches_row_options)),
        CHECK (array_length(branches_matrix, 2) = cardinality(branches_col_options))
    )
    SQL

    $db.query(q:to/SQL/);
    INSERT INTO pers (pers_id, pers_email, pers_password)
              VALUES (-42000, 'foo@agrammon.ch', 'XXX')
    SQL

    $db.query(q:to/SQL/, $uid);
    INSERT INTO dataset (dataset_id, dataset_name, dataset_pers, dataset_version, dataset_guivariant, dataset_modelvariant)
                 VALUES (-42000, 'BranchTest', $1, '6.0', 'Regional', 'Base')
    SQL

    $db.query(q:to/SQL/);
    INSERT INTO data_instance (data_instance_id, data_instance_dataset, data_instance_name)
                       VALUES (-91000, -42000, 'Branched')
    SQL

    $db.query(q:to/SQL/);
    INSERT INTO data (data_id, data_dataset, data_var, data_instance_id, data_val)
                 VALUES (-76315980, -42000, 'Livestock::Poultry[]::Housing::Type::housing_type',            -91000, 'branched'),
                        (-76315982, -42000, 'Livestock::Poultry[]::Housing::Type::manure_removal_interval', -91000, 'branched')
    SQL

    # Single self-describing branch row (issue #421 task 3). row-axis = manure
    # removal interval (6 options), col-axis = housing type (4 options); the
    # 6x4 matrix is the old flattened 24-value vector reshaped row-major.
    $db.query(q:to/SQL/);
    INSERT INTO branches (branches_id, branches_row_var, branches_col_var,
                          branches_row_options, branches_col_options, branches_matrix)
         VALUES (-30950, -76315982, -76315980,
                 '{less_than_twice_a_month,twice_a_month,3_to_4_times_a_month,more_than_4_times_a_month,once_a_day,no_manure_belt}',
                 '{manure_belt_with_manure_belt_drying_system,manure_belt_without_manure_belt_drying_system,deep_pit,deep_litter}',
                 '{{0,0,0,0},{0,0,0,15.9},{31.5,33.5,0,0},{0,0,0,0},{0,2.2,0,0},{0,0,0,16.9}}')
    SQL

    return 1;
}

sub transactionally(&test) is export {
    my $*AGRAMMON-DB-HANDLE = my $db = $*AGRAMMON-DB-CONNECTION.db;
    $db.begin;
    test($db);
    LEAVE $db.finish;
}
