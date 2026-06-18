-- Issue #421 task 3: collapse the two-row-per-branch `branches` design into one
-- self-describing row per branch (Option B). Idempotent: re-running is a no-op.
-- Run AFTER migrate-issue-421-rename-data-new-to-data.sql and
-- migrate-issue-421-data-instance-table.sql.
BEGIN;

DO $migrate$
BEGIN
    -- already migrated?
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_name = 'branches' AND column_name = 'branches_matrix') THEN
        RAISE NOTICE 'branches already migrated to single-row shape, skipping';
        RETURN;
    END IF;

    -- temporary helper: reshape a flat numeric[] into a 2-D numeric[] with ncols
    CREATE OR REPLACE FUNCTION pg_temp.reshape_1d_to_2d(arr numeric[], ncols int)
    RETURNS numeric[] LANGUAGE plpgsql IMMUTABLE AS $fn$
    DECLARE n int; nrows int; res numeric[]; r int; c int;
    BEGIN
        IF arr IS NULL OR ncols IS NULL OR ncols = 0 THEN RETURN NULL; END IF;
        n := array_length(arr, 1);
        nrows := n / ncols;
        res := array_fill(NULL::numeric, ARRAY[nrows, ncols]);
        FOR r IN 1..nrows LOOP
            FOR c IN 1..ncols LOOP
                res[r][c] := arr[(r - 1) * ncols + c];
            END LOOP;
        END LOOP;
        RETURN res;
    END $fn$;

    -- 1. add the new columns (nullable for now)
    ALTER TABLE branches ADD COLUMN branches_row_var     integer;
    ALTER TABLE branches ADD COLUMN branches_col_var     integer;
    ALTER TABLE branches ADD COLUMN branches_row_options text[];
    ALTER TABLE branches ADD COLUMN branches_col_options text[];
    ALTER TABLE branches ADD COLUMN branches_matrix      numeric[];

    -- 2. pair the two old rows per branch (they share a data instance) and fold
    --    them into the rn=1 row. Order within a pair by (instance name, data_id):
    --    first = row axis, second = col axis (matches the old read convention).
    WITH ranked AS (
        SELECT b.branches_id, b.branches_var, b.branches_data, b.branches_options,
               d.data_instance_id, di.data_instance_name,
               row_number() OVER (PARTITION BY d.data_instance_id
                                  ORDER BY di.data_instance_name, d.data_id) AS rn
          FROM branches b
          JOIN data d ON (b.branches_var = d.data_id)
          LEFT JOIN data_instance di ON (d.data_instance_id = di.data_instance_id)
    ),
    pairs AS (
        SELECT data_instance_id,
               max(branches_id)      FILTER (WHERE rn = 1) AS keep_id,
               max(branches_id)      FILTER (WHERE rn = 2) AS drop_id,
               max(branches_var)     FILTER (WHERE rn = 1) AS row_var,
               max(branches_var)     FILTER (WHERE rn = 2) AS col_var,
               max(branches_options) FILTER (WHERE rn = 1) AS row_options,
               max(branches_options) FILTER (WHERE rn = 2) AS col_options,
               max(branches_data)    FILTER (WHERE rn = 1) AS flat_data,
               max(array_length(branches_options, 1)) FILTER (WHERE rn = 2) AS ncols
          FROM ranked
         GROUP BY data_instance_id
    )
    UPDATE branches b
       SET branches_row_var     = p.row_var,
           branches_col_var     = p.col_var,
           branches_row_options = p.row_options,
           branches_col_options = p.col_options,
           branches_matrix      = pg_temp.reshape_1d_to_2d(p.flat_data, p.ncols)
      FROM pairs p
     WHERE b.branches_id = p.keep_id;

    -- 3. delete the now-redundant sibling rows
    DELETE FROM branches b USING (
        SELECT max(branches_id) FILTER (WHERE rn = 2) AS drop_id
          FROM (
            SELECT b.branches_id, d.data_instance_id,
                   row_number() OVER (PARTITION BY d.data_instance_id
                                      ORDER BY di.data_instance_name, d.data_id) AS rn
              FROM branches b
              JOIN data d ON (b.branches_var = d.data_id)
              LEFT JOIN data_instance di ON (d.data_instance_id = di.data_instance_id)
          ) r
         GROUP BY data_instance_id
    ) p
    WHERE b.branches_id = p.drop_id;

    -- 4. drop the old columns
    ALTER TABLE branches DROP COLUMN branches_var;
    ALTER TABLE branches DROP COLUMN branches_data;
    ALTER TABLE branches DROP COLUMN branches_options;

    -- 5. enforce the new shape
    ALTER TABLE branches ALTER COLUMN branches_row_var     SET NOT NULL;
    ALTER TABLE branches ALTER COLUMN branches_col_var     SET NOT NULL;
    ALTER TABLE branches ALTER COLUMN branches_row_options SET NOT NULL;
    ALTER TABLE branches ALTER COLUMN branches_col_options SET NOT NULL;
    ALTER TABLE branches ALTER COLUMN branches_matrix      SET NOT NULL;
    ALTER TABLE branches ADD CONSTRAINT branches_row_var_key UNIQUE (branches_row_var);
    ALTER TABLE branches ADD CONSTRAINT branches_col_var_key UNIQUE (branches_col_var);
    ALTER TABLE branches ADD CONSTRAINT branches_row_var_fkey
        FOREIGN KEY (branches_row_var) REFERENCES data(data_id) ON DELETE CASCADE;
    ALTER TABLE branches ADD CONSTRAINT branches_col_var_fkey
        FOREIGN KEY (branches_col_var) REFERENCES data(data_id) ON DELETE CASCADE;
    ALTER TABLE branches ADD CONSTRAINT branches_matrix_2d
        CHECK (array_ndims(branches_matrix) = 2);
    ALTER TABLE branches ADD CONSTRAINT branches_matrix_rows
        CHECK (array_length(branches_matrix, 1) = cardinality(branches_row_options));
    ALTER TABLE branches ADD CONSTRAINT branches_matrix_cols
        CHECK (array_length(branches_matrix, 2) = cardinality(branches_col_options));
END $migrate$;

COMMIT;
