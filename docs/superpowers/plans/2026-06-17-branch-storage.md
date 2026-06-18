# Branch Storage Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the fragile two-row, `.rotor`-inferred branch matrix storage (issue #421 task 3) with one self-describing `branches` row per branch — explicit row/col variable FKs, row/col option arrays, and a native `numeric[][]` matrix — and make all branch writes pair-aware.

**Architecture:** One `branches` row per branch pair (was two). The two `data` rows (the branched variables) stay; the matrix is stored once as a native 2-D Postgres array with explicit axis↔variable binding. The model-run read, the editor load/store, and clone are rewritten to be order-independent. The GUI instance-copy path is fixed to persist branches via the pair-aware `store_branch_data` instead of the axis-blind per-variable `store_data`; that per-variable persistence is then retired. No user-visible GUI change.

**Tech Stack:** Raku (`DB::Pg`), PostgreSQL (`numeric[][]`, plpgsql migration helper), Qooxdoo JS frontend.

**Spec:** `docs/superpowers/specs/2026-06-17-branch-storage-design.md`

---

## Pre-flight notes for the executor

- **Branch:** work happens on `refactor/issue-421-branch-storage` (already created off `main`).
- **Do NOT touch the dev/test DBs unattended.** The user will apply the migration to the dev DB (`:55433`) and GUI-test before anything is pushed. Validate autonomously on **throwaway scratch DBs only**.
- **DDL with `DROP COLUMN`** (the migration) must never run against `agrammon_test`/dev DB without the user's explicit confirmation. Scratch DBs you create yourself are fine.
- **Two scratch-DB validation modes** are used below:
  - *Fresh-schema scratch DB* — tables created new with the new shape (validates new code; no migration needed).
  - *Seeded-old scratch DB* — seeded with old-shape `branches`, then migrated (validates the migration conversion).
- **Expected red windows:** after Task 1 (schema) the branched DB tests are red until their fixture+code task lands. Run the full branched test after each backend task.

### Scratch DB helper (used by several tasks)

Create a fresh scratch DB + config pointing at it:

```bash
export TMPDIR=/scratch/zaucker/tmp
SCRATCH=branch_scratch
PGPASSWORD=agrammon dropdb   -h localhost -p 55432 -U agrammon --if-exists $SCRATCH
PGPASSWORD=agrammon createdb -h localhost -p 55432 -U agrammon $SCRATCH
# config the DB-integration tests will read
sed 's/name:     agrammon_test/name:     branch_scratch/' \
    t/test-data/agrammon.cfg.yaml > /scratch/zaucker/tmp/agrammon.scratch.cfg.yaml
```

Run a DB-integration test against the scratch DB:

```bash
AGRAMMON_CFG=/scratch/zaucker/tmp/agrammon.scratch.cfg.yaml \
  raku -Ilib -It/lib t/datasource-db.rakutest
```

(The test's `prepare-*` helpers create their own tables via `AgrammonTest`/inline DDL with the new shape, so a fresh scratch DB needs no migration.)

---

## File Structure

- `db/migrate-issue-421-branch-storage.sql` — **new** one-time migration (ALTER in place; idempotent).
- `db/schema.sql` — **modify** the `branches` table DDL + constraints + FK + grants.
- `t/lib/AgrammonTest.rakumod` — **modify** the `branches` CREATE + the seed branch INSERT.
- `lib/Agrammon/DataSource/DB.rakumod` — **modify** `read` (drop the state machine + `.rotor`; dedicated branched query).
- `lib/Agrammon/DB/Dataset.rakumod` — **modify** `store-branch-data`, `load-branch-data`, `clone`; **retire** the `!store-instance-variable` / `store-input` `@branches` persistence.
- `t/datasource-db.rakutest` — **modify** `prepare-test-db-branched-data` (+ dead `prepare-test-db-schema`) fixture; assertions stay.
- `t/dataset.rakutest` — **modify** `store-input() with branches` + `Store and load branch data` subtests; add non-square round-trip.
- `frontend/source/class/agrammon/module/input/NavFolder.js` — **modify** `setDataset` storeAll loop (pair-aware branch write).
- `frontend/source/class/agrammon/module/input/PropTable.js` — **modify** `__storeData` (drop unused branches/options plumbing).
- `t/test-data/agrammon.schema.sql`, `t/test-data/agrammon_test.dump.sql` — **modify** (regenerate) CI fixtures.

---

## Task 1: New schema + migration (DDL foundation)

**Files:**
- Create: `db/migrate-issue-421-branch-storage.sql`
- Modify: `db/schema.sql` (branches table region, ~lines 178-183, 523-535, 663-667)
- Modify: `t/lib/AgrammonTest.rakumod:80-113`

- [ ] **Step 1: Write the migration SQL**

Create `db/migrate-issue-421-branch-storage.sql`:

```sql
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
```

- [ ] **Step 2: Validate the migration on a SEEDED-OLD scratch DB**

This proves the conversion folds two old rows into one correct new row. Run:

```bash
export TMPDIR=/scratch/zaucker/tmp
PGPASSWORD=agrammon dropdb   -h localhost -p 55432 -U agrammon --if-exists branch_mig
PGPASSWORD=agrammon createdb -h localhost -p 55432 -U agrammon branch_mig
PGPASSWORD=agrammon psql -h localhost -p 55432 -U agrammon -d branch_mig <<'SQL'
CREATE TABLE dataset (dataset_id serial primary key, dataset_name text);
CREATE TABLE data_instance (data_instance_id serial primary key,
    data_instance_dataset int, data_instance_name text, data_instance_order int);
CREATE TABLE data (data_id serial primary key, data_dataset int, data_var text,
    data_val text, data_instance_id int references data_instance(data_instance_id));
CREATE TABLE branches (branches_id serial primary key,
    branches_var int unique references data(data_id) on delete cascade,
    branches_data numeric[], branches_options text[]);
INSERT INTO dataset (dataset_id, dataset_name) VALUES (1, 'X');
INSERT INTO data_instance (data_instance_id, data_instance_dataset, data_instance_name)
    VALUES (10, 1, 'Inst');
-- non-square 3x2: row var (flat-a, 3 opts) inserted first, col var (flat-b, 2 opts) second
INSERT INTO data (data_id, data_dataset, data_var, data_val, data_instance_id) VALUES
    (100, 1, 'M[]::S::flat-a', 'branched', 10),
    (101, 1, 'M[]::S::flat-b', 'branched', 10);
INSERT INTO branches (branches_var, branches_data, branches_options) VALUES
    (100, '{12,18,8,12,20,30}', '{x,y,z}'),
    (101, '{12,18,8,12,20,30}', '{a,b}');
SQL
PGPASSWORD=agrammon psql -h localhost -p 55432 -U agrammon -d branch_mig \
    -f db/migrate-issue-421-branch-storage.sql
PGPASSWORD=agrammon psql -h localhost -p 55432 -U agrammon -d branch_mig -c \
"SELECT count(*) AS rows, branches_row_var, branches_col_var,
        branches_row_options, branches_col_options, branches_matrix
   FROM branches GROUP BY 2,3,4,5,6;"
```

Expected: exactly **1 row**, `branches_row_var=100`, `branches_col_var=101`,
`branches_row_options={x,y,z}`, `branches_col_options={a,b}`,
`branches_matrix={{12,18},{8,12},{20,30}}` (3×2). Re-running the `-f` migration a
second time prints the "already migrated, skipping" notice and leaves 1 row.

- [ ] **Step 3: Update `db/schema.sql`**

Replace the `CREATE TABLE public.branches (...)` body (lines 178-183) with:

```sql
CREATE TABLE public.branches (
    branches_id integer NOT NULL,
    branches_row_var integer NOT NULL,
    branches_col_var integer NOT NULL,
    branches_row_options text[] NOT NULL,
    branches_col_options text[] NOT NULL,
    branches_matrix numeric[] NOT NULL,
    CONSTRAINT branches_matrix_2d CHECK ((array_ndims(branches_matrix) = 2)),
    CONSTRAINT branches_matrix_rows CHECK ((array_length(branches_matrix, 1) = cardinality(branches_row_options))),
    CONSTRAINT branches_matrix_cols CHECK ((array_length(branches_matrix, 2) = cardinality(branches_col_options)))
);
```

Replace the UNIQUE constraint (lines 523-527, `branches_branches_var_key` on `branches_var`) with two:

```sql
ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_row_var_key UNIQUE (branches_row_var);
ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_col_var_key UNIQUE (branches_col_var);
```

Replace the FK (lines 663-667, `branches_branches_var_fkey`) with two:

```sql
ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_row_var_fkey FOREIGN KEY (branches_row_var) REFERENCES public.data(data_id) ON DELETE CASCADE;
ALTER TABLE ONLY public.branches
    ADD CONSTRAINT branches_col_var_fkey FOREIGN KEY (branches_col_var) REFERENCES public.data(data_id) ON DELETE CASCADE;
```

(Leave the sequence + `branches_pkey` + GRANT blocks unchanged.)

- [ ] **Step 4: Update `t/lib/AgrammonTest.rakumod` branches DDL (lines 80-86)**

```raku
    $db.query(q:to/SQL/);
    CREATE TABLE IF NOT EXISTS branches (
        branches_id          SERIAL NOT NULL PRIMARY KEY,
        branches_row_var     INTEGER NOT NULL UNIQUE REFERENCES data(data_id) ON DELETE CASCADE,
        branches_col_var     INTEGER NOT NULL UNIQUE REFERENCES data(data_id) ON DELETE CASCADE,
        branches_row_options TEXT[]    NOT NULL,
        branches_col_options TEXT[]    NOT NULL,
        branches_matrix      NUMERIC[] NOT NULL,
        CHECK (array_ndims(branches_matrix) = 2),
        CHECK (array_length(branches_matrix, 1) = cardinality(branches_row_options)),
        CHECK (array_length(branches_matrix, 2) = cardinality(branches_col_options))
    )
    SQL
```

- [ ] **Step 5: Update the AgrammonTest seed branch INSERT (lines 109-113)**

The old seed (two rows, `data_id` -76315980 housing / -76315982 manure_removal,
both with the same flat 24-value matrix). Housing = 4 opts, manure = 6 opts. The
old read made the **lower** `branches_var` the row axis: -76315982 < -76315980, so
manure (6) = rows, housing (4) = cols → 6×4. Preserve that orientation:

```raku
    $db.query(q:to/SQL/);
    INSERT INTO branches (branches_id, branches_row_var, branches_col_var,
                          branches_row_options, branches_col_options, branches_matrix)
         VALUES (-30950, -76315982, -76315980,
                 '{less_than_twice_a_month,twice_a_month,3_to_4_times_a_month,more_than_4_times_a_month,once_a_day,no_manure_belt}',
                 '{manure_belt_with_manure_belt_drying_system,manure_belt_without_manure_belt_drying_system,deep_pit,deep_litter}',
                 '{{0,0,0,0},{0,0,0,0},{0,0,0,15.9},{31.5,33.5,0,0},{0,0,0,0},{0,2.2,0,0}}')
    SQL
```

(The 24 values `{0,0,0,0,0,0,0,15.9,31.5,33.5,0,0,0,0,0,0,0,2.2,0,0,0,0,0,16.9}`
reshaped 6×4 row-major. Note: this seed is only consumed by the `dataset.rakutest`
`Store and load branch data` subtest, which **overwrites** it via `store-branch-data`
and asserts the overwritten values, so the exact reshape here only needs to be a
valid 6×4 matrix. The last value `16.9` lands at `[6][4]`.)

Correct the reshape to include all 24 values: `{{0,0,0,0},{0,0,0,15.9},{31.5,33.5,0,0},{0,0,0,0},{0,2.2,0,0},{0,0,0,16.9}}`.

- [ ] **Step 6: Verify schema files parse + scratch DB builds the new table**

```bash
export TMPDIR=/scratch/zaucker/tmp
PGPASSWORD=agrammon dropdb   -h localhost -p 55432 -U agrammon --if-exists branch_scratch
PGPASSWORD=agrammon createdb -h localhost -p 55432 -U agrammon branch_scratch
PGPASSWORD=agrammon psql -h localhost -p 55432 -U agrammon -d branch_scratch \
    -v ON_ERROR_STOP=1 -f db/schema.sql && echo "schema.sql OK"
```

Expected: `schema.sql OK` (full schema loads with the new branches table).

- [ ] **Step 7: Commit**

```bash
git add db/migrate-issue-421-branch-storage.sql db/schema.sql t/lib/AgrammonTest.rakumod
git commit -m "db(#421): branches single-row schema + migration (task 3)"
```

> ⚠️ After this task the branched **DB-integration** tests are RED (code still
> reads old columns). Tasks 2-3 restore them.

---

## Task 2: Read path — `DataSource::DB.read`

**Files:**
- Modify: `lib/Agrammon/DataSource/DB.rakumod:28-141`
- Modify: `t/datasource-db.rakutest:345-398` (`prepare-test-db-branched-data`) and the dead `prepare-test-db-schema:443-450`
- Test: `t/datasource-db.rakutest` branched subtests (existing assertions are the spec)

- [ ] **Step 1: Update the branched fixture `prepare-test-db-branched-data` (lines 366-397)**

Replace the two `$sth-branch` inserts-per-pair with one pair-row insert. Old data:
both vars share flat `{12,18,8,12,20,30}`; flat-a `{x,y,z}` (3) inserted first =
rows, flat-b `{a,b}` (2) second = cols → matrix 3×2 row-major
`{{12,18},{8,12},{20,30}}`. New fixture body:

```raku
    my $sth-data = $db.prepare(q:to/STATEMENT/);
    INSERT INTO data (data_dataset, data_instance_id, data_var, data_val)
    VALUES ($1, $2, $3, $4)
    RETURNING data_id;
    STATEMENT

    my $sth-branch = $db.prepare(q:to/STATEMENT/);
    INSERT INTO branches (branches_row_var, branches_col_var,
                          branches_row_options, branches_col_options, branches_matrix)
    VALUES ($1, $2, $3, $4, $5)
    STATEMENT

    # branch over inputs from same submodule (Instance A)
    $sth-data.execute($datasetId, $iidA, 'Test::Base[]::Sub::dist-me', 1000);
    $sth-data.execute($datasetId, $iidA, 'Test::Base[]::Sub::simple', 42);
    my $a-row = $sth-data.execute($datasetId, $iidA, 'Test::Base[]::AnotherSub::flat-a', 'branched').value;
    my $a-col = $sth-data.execute($datasetId, $iidA, 'Test::Base[]::AnotherSub::flat-b', 'branched').value;
    $sth-branch.execute($a-row, $a-col, '{x,y,z}', '{a,b}', [[12,18],[8,12],[20,30]]);
    $sth-data.execute($datasetId, $iidA, 'Test::Base[]::AnotherSub::simple', 101);

    # branch over inputs from different submodules (Instance B)
    $sth-data.execute($datasetId, $iidB, 'Test::Base[]::Sub::dist-me', 1000);
    $sth-data.execute($datasetId, $iidB, 'Test::Base[]::Sub::simple', 42);
    my $b-row = $sth-data.execute($datasetId, $iidB, 'Test::Base[]::AnotherSubA::flat-a', 'branched').value;
    my $b-col = $sth-data.execute($datasetId, $iidB, 'Test::Base[]::AnotherSubB::flat-b', 'branched').value;
    $sth-branch.execute($b-row, $b-col, '{x,y,z}', '{a,b}', [[12,18],[8,12],[20,30]]);
    $sth-data.execute($datasetId, $iidB, 'Test::Base[]::AnotherSubA::simple', 101);
```

Also update the dead `prepare-test-db-schema` branches DDL (lines 443-450) to the
new shape for consistency (it is not called, but keep it honest):

```raku
    $db.query(q:to/STATEMENT/);
    CREATE TABLE IF NOT EXISTS branches (
        branches_id          SERIAL NOT NULL PRIMARY KEY,
        branches_row_var     INT4 NOT NULL UNIQUE REFERENCES data(data_id) ON DELETE CASCADE,
        branches_col_var     INT4 NOT NULL UNIQUE REFERENCES data(data_id) ON DELETE CASCADE,
        branches_row_options TEXT[] NOT NULL,
        branches_col_options TEXT[] NOT NULL,
        branches_matrix      NUMERIC[] NOT NULL
    )
    STATEMENT
```

- [ ] **Step 2: Run the branched read test — verify it FAILS (old read code)**

```bash
export TMPDIR=/scratch/zaucker/tmp
PGPASSWORD=agrammon dropdb   -h localhost -p 55432 -U agrammon --if-exists branch_scratch
PGPASSWORD=agrammon createdb -h localhost -p 55432 -U agrammon branch_scratch
sed 's/name:     agrammon_test/name:     branch_scratch/' \
    t/test-data/agrammon.cfg.yaml > /scratch/zaucker/tmp/agrammon.scratch.cfg.yaml
AGRAMMON_CFG=/scratch/zaucker/tmp/agrammon.scratch.cfg.yaml \
  raku -Ilib -It/lib t/datasource-db.rakutest 2>&1 | tail -25
```

Expected: the branched subtests FAIL (old `read` references `branches_data`/`branches_options` columns that no longer exist).

- [ ] **Step 3: Rewrite `read` in `lib/Agrammon/DataSource/DB.rakumod`**

Replace the whole method body (28-141). Main query loses the branches join and the
branched state machine; a dedicated query rebuilds branches. Note column-index
shift: comment moves to `@row[3]`.

```raku
    method read($user, Str $dataset, %variant) {
        self.with-db: -> $db {
            my $results = $db.query(q:to/STATEMENT/, $user, $dataset, %variant<version>, %variant<gui>, %variant<model>);
                SELECT data_var, data_val, i.data_instance_name, data_comment
                FROM data
                LEFT JOIN data_instance i ON (data.data_instance_id = i.data_instance_id)
                WHERE data_dataset=dataset_name2id($1,$2,$3,$4,$5)
                    AND data_var not like '%ignore'
                ORDER BY i.data_instance_name, data_var, data_val
            STATEMENT
            my @rows = $results.arrays;
            my $dist-input = Agrammon::Inputs::Distribution.new(
                simulation-name => 'DB',
                dataset-id      => $dataset
            );

            my @flattend-to-add;

            for @rows -> @row {
                my $module-var = @row[0];
                my $value      = maybe-numify(@row[1]);
                my $instance   = @row[2] // '';
                my $comment    = @row[3];
                state $flattend-prefix = '';
                state Flattened $current-flattened;

                # branched data rows are handled by the dedicated query below
                next if $value && $value eq 'branched';

                if $instance {
                    if $module-var ~~ m/(.+)'[]'(.+)/ {
                        my $tax     = "$0";
                        my $sub-var = "$1";
                        my ($sub-tax, $var);
                        if $sub-var ~~ m/'::'(.+)'::'(.+)/ {
                            $sub-tax = "$0";
                            $var     = "$1";
                        }
                        else {
                            $sub-tax = '';
                            $sub-var ~~ s/'::'//;
                            $var = $sub-var;
                        }

                        if $value and $value eq 'flattened' {
                            $flattend-prefix = $var;
                            $current-flattened = Flattened.new:
                                    taxonomy => $tax,
                                    instance-id => $instance,
                                    sub-taxonomy => $sub-tax,
                                    input-name => $var;
                            push @flattend-to-add, $current-flattened;
                        }
                        elsif $flattend-prefix && $var.starts-with($flattend-prefix ~ '_flattened') {
                            my $key = $var.substr(($flattend-prefix ~ '_flattened00_').chars);
                            $key ~~ s:g/ ' ' /_/;
                            $current-flattened.value-percentages{$key} = $value;
                        }
                        else {
                            $dist-input.add-multi-input($tax, $instance, $sub-tax, $var, $value, :$comment);
                            $flattend-prefix = '';
                        }
                    }
                    else {
                        die "Malformed data: module-var=$module-var";
                    }
                }
                else {
                    $module-var ~~ m/(.+)'::'(.+)/;
                    my $tax     = "$0";
                    my $var     = "$1";
                    $dist-input.add-single-input($tax, $var, $value, :$comment);
                }
            }

            for @flattend-to-add {
                $dist-input.add-multi-input-flattened(.taxonomy, .instance-id, .sub-taxonomy,
                        .input-name, .value-percentages);
            }

            # branched inputs: one self-describing row each, joined to both data rows
            my @branches = $db.query(q:to/STATEMENT/, $user, $dataset, %variant<version>, %variant<gui>, %variant<model>).arrays;
                SELECT rv.data_var, cv.data_var, ri.data_instance_name,
                       b.branches_row_options, b.branches_col_options, b.branches_matrix
                FROM branches b
                JOIN data rv ON (b.branches_row_var = rv.data_id)
                JOIN data cv ON (b.branches_col_var = cv.data_id)
                LEFT JOIN data_instance ri ON (rv.data_instance_id = ri.data_instance_id)
                WHERE rv.data_dataset = dataset_name2id($1,$2,$3,$4,$5)
            STATEMENT

            for @branches -> @b {
                my ($row-tax, $row-sub, $row-var) = parse-branch-var(@b[0]);
                my ($col-tax, $col-sub, $col-var) = parse-branch-var(@b[1]);
                $dist-input.add-multi-input-branched(
                    $row-tax, @b[2],
                    $row-sub, $row-var, @b[3].list,
                    $col-sub, $col-var, @b[4].list,
                    @b[5]);
            }

            return $dist-input;
        }
    }

    # Parse a stored branched var name `Taxonomy[]::SubTax::var` (or
    # `Taxonomy[]::var` with no sub-taxonomy) into (taxonomy, sub-taxonomy, var).
    sub parse-branch-var(Str $module-var) {
        $module-var ~~ m/(.+)'[]'(.+)/ or die "Malformed branched var: $module-var";
        my $tax     = "$0";
        my $sub-var = "$1";
        my ($sub-tax, $var);
        if $sub-var ~~ m/'::'(.+)'::'(.+)/ {
            $sub-tax = "$0";
            $var     = "$1";
        }
        else {
            $sub-tax = '';
            $sub-var ~~ s/'::'//;
            $var = $sub-var;
        }
        return ($tax, $sub-tax, $var);
    }
```

Note: `add-multi-input-branched` signature is `($taxonomy, $instance-id, $sub-taxonomy-a, $input-name-a, @input-values-a, $sub-taxonomy-b, $input-name-b, @input-values-b, @matrix)`. The row variable supplies taxonomy + A-axis; the col variable supplies the B-axis. `@b[5]` (the `numeric[][]`) is passed straight as `@matrix` (Array-of-Array, exactly what `add-multi-input-branched` validates as `@matrix.elems == @input-values-a` rows × `@input-values-b` cols).

- [ ] **Step 4: Run the branched read test — verify it PASSES**

```bash
export TMPDIR=/scratch/zaucker/tmp
PGPASSWORD=agrammon dropdb   -h localhost -p 55432 -U agrammon --if-exists branch_scratch
PGPASSWORD=agrammon createdb -h localhost -p 55432 -U agrammon branch_scratch
AGRAMMON_CFG=/scratch/zaucker/tmp/agrammon.scratch.cfg.yaml \
  raku -Ilib -It/lib t/datasource-db.rakutest 2>&1 | tail -15
```

Expected: all 22 datasource-db assertions PASS (single, flattened, branched, comments).

- [ ] **Step 5: Commit**

```bash
git add lib/Agrammon/DataSource/DB.rakumod t/datasource-db.rakutest
git commit -m "db(#421): read branches from single self-describing row (task 3)"
```

---

## Task 3: `store-branch-data` / `load-branch-data`

**Files:**
- Modify: `lib/Agrammon/DB/Dataset.rakumod:797-869`
- Test: `t/dataset.rakutest:182-258` (`Store and load branch data`) + new non-square subtest

- [ ] **Step 1: Add a non-square round-trip assertion to `dataset.rakutest`**

After the existing `Store and load branch data` subtest (line 258), add:

```raku
    subtest 'Store and load branch data — non-square matrix' => {
        plan 2;
        my %d = (
            instance => 'Branched',
            vars     => [
                'Livestock::Poultry[]::Housing::Type::housing_type',
                'Livestock::Poultry[]::Housing::Type::manure_removal_interval',
            ],
            options  => {
                'Livestock::Poultry[]::Housing::Type::housing_type' =>
                    ['deep pit', 'deep litter'],                       # 2 rows
                'Livestock::Poultry[]::Housing::Type::manure_removal_interval' =>
                    ['once a day', 'twice a month', 'no manure belt'], # 3 cols
            },
            data     => [[10, 20, 30], [15, 5, 20]],                   # 2x3
        );
        $dataset = Agrammon::DB::Dataset.new(:name<BranchTest>, :$user,
            :agrammon-variant(version => '6.0', gui => 'Regional', model => 'Base')).load;
        lives-ok { $dataset.store-branch-data(%d<vars>, %d<instance>, %d<options>, %d<data>) },
            'Store non-square branch data';
        my $r = $dataset.load-branch-data(%d<vars>, %d<instance>);
        is-deeply $r<fractions>, [10e0, 20e0, 30e0, 15e0, 5e0, 20e0],
            'Non-square fractions round-trip row-major';
    }
```

- [ ] **Step 2: Run — verify it FAILS (old store/load use dropped columns)**

```bash
export TMPDIR=/scratch/zaucker/tmp
PGPASSWORD=agrammon dropdb   -h localhost -p 55432 -U agrammon --if-exists branch_scratch
PGPASSWORD=agrammon createdb -h localhost -p 55432 -U agrammon branch_scratch
AGRAMMON_CFG=/scratch/zaucker/tmp/agrammon.scratch.cfg.yaml \
  raku -Ilib -It/lib t/dataset.rakutest 2>&1 | tail -25
```

Expected: `Store and load branch data` subtests FAIL (column errors).

- [ ] **Step 3: Rewrite `store-branch-data` (lines 797-840)**

```raku
    method store-branch-data(@vars, Str $instance, %options, @fractions) {
        my $dataset-name = $!name;
        my $row-var = @vars[0];
        my $col-var = @vars[1];

        self.with-db: -> $db {
            my $username = $!user.username;
            my %id-of = $db.query(q:to/SQL/, $username, $dataset-name, |self!variant, $row-var, $col-var, $instance).hashes
                          .map({ .<data_var> => .<data_id> });
            SELECT data_id, data_var
              FROM data
             WHERE data_dataset=dataset_name2id($1,$2,$3,$4,$5)
               AND data_var IN ($6,$7)
               AND data_instance_id = (SELECT data_instance_id FROM data_instance
                                        WHERE data_instance_dataset = dataset_name2id($1,$2,$3,$4,$5)
                                          AND data_instance_name = $8)
            SQL

            my @row-options = %options{$row-var}.map(*.subst(' ', '_', :g));
            my @col-options = %options{$col-var}.map(*.subst(' ', '_', :g));
            my @matrix = @fractions.map({ $_.map(+*).Array }).Array;

            my $ret = $db.query(q:to/SQL/, %id-of{$row-var}, %id-of{$col-var}, @row-options, @col-options, @matrix);
                INSERT INTO branches (branches_row_var, branches_col_var,
                                      branches_row_options, branches_col_options, branches_matrix)
                              VALUES ($1, $2, $3, $4, $5)
                ON CONFLICT (branches_row_var)
                DO UPDATE SET branches_col_var     = EXCLUDED.branches_col_var,
                              branches_row_options = EXCLUDED.branches_row_options,
                              branches_col_options = EXCLUDED.branches_col_options,
                              branches_matrix      = EXCLUDED.branches_matrix
                SQL
            die X::Agrammon::DB::Dataset::StoreBranchDataFailed.new(:variable($row-var)) unless $ret;
        }

        self.with-db: -> $db {
            $db.query(q:to/SQL/, $!user.username, $dataset-name, |self!variant);
                    UPDATE dataset SET dataset_mod_date = CURRENT_TIMESTAMP
                     WHERE dataset_id=dataset_name2id($1,$2,$3,$4,$5)
                SQL
        }
    }
```

- [ ] **Step 4: Rewrite `load-branch-data` (lines 842-869)**

```raku
    method load-branch-data(@var-names, Str $instance) {
        my $data;
        self.with-db: -> $db {
            my $username = $!user.username;
            my @b = $db.query(q:to/SQL/, $username, $!name, |self!variant, @var-names[0], $instance).hashes;
                SELECT b.branches_row_options, b.branches_col_options, b.branches_matrix
                  FROM branches b
                  JOIN data rv ON (b.branches_row_var = rv.data_id)
                 WHERE rv.data_dataset = dataset_name2id($1,$2,$3,$4,$5)
                   AND rv.data_var = $6
                   AND rv.data_instance_id = (SELECT data_instance_id FROM data_instance
                                               WHERE data_instance_dataset = dataset_name2id($1,$2,$3,$4,$5)
                                                 AND data_instance_name = $7)
            SQL
            with @b[0] -> %row {
                $data = {
                    fractions => %row<branches_matrix>.flat.Array,
                    options   => [ %row<branches_row_options>, %row<branches_col_options> ],
                };
            }
            else {
                $data = { fractions => Nil, options => [] };
            }
        }
        return $data;
    }
```

Note: `@var-names[0]` is the row variable (the frontend always passes `vars[0]`=row). The unique `branches_row_var` makes that sufficient to find the row.

- [ ] **Step 5: Run — verify PASS**

```bash
export TMPDIR=/scratch/zaucker/tmp
PGPASSWORD=agrammon dropdb   -h localhost -p 55432 -U agrammon --if-exists branch_scratch
PGPASSWORD=agrammon createdb -h localhost -p 55432 -U agrammon branch_scratch
AGRAMMON_CFG=/scratch/zaucker/tmp/agrammon.scratch.cfg.yaml \
  raku -Ilib -It/lib t/dataset.rakutest 2>&1 | tail -20
```

Expected: `Store and load branch data` (both square + non-square) PASS. The
`store-input() with branches` subtest may still pass/fail depending on Task 5 —
ignore it here; it is fixed in Task 5.

- [ ] **Step 6: Commit**

```bash
git add lib/Agrammon/DB/Dataset.rakumod t/dataset.rakutest
git commit -m "db(#421): store/load branch data as single 2-D row (task 3)"
```

---

## Task 4: `clone`

**Files:**
- Modify: `lib/Agrammon/DB/Dataset.rakumod:256-290` (the branch-clone portion of `clone`)
- Test: `t/dataset.rakutest` — add a clone branch round-trip subtest

- [ ] **Step 1: Add a clone round-trip subtest to `dataset.rakutest`**

After the non-square subtest from Task 3, add (uses the `BranchTest` dataset which
already has a branch in the `Branched` instance):

```raku
    subtest 'clone copies branch matrix (non-square safe)' => {
        plan 2;
        my $src = Agrammon::DB::Dataset.new(:name<BranchTest>, :$user,
            :agrammon-variant(version => '6.0', gui => 'Regional', model => 'Base')).load;
        # set a known non-square matrix on the source first
        my @vars = (
            'Livestock::Poultry[]::Housing::Type::housing_type',
            'Livestock::Poultry[]::Housing::Type::manure_removal_interval',
        );
        $src.store-branch-data(@vars, 'Branched',
            { @vars[0] => ['deep pit', 'deep litter'],
              @vars[1] => ['once a day', 'twice a month', 'no manure belt'] },
            [[1, 2, 3], [4, 5, 6]]);
        lives-ok { $src.clone(:new-username($user.username), :old-dataset<BranchTest>, :new-dataset<BranchClone>) },
            'Clone dataset with branch';
        my $clone = Agrammon::DB::Dataset.new(:name<BranchClone>, :$user,
            :agrammon-variant(version => '6.0', gui => 'Regional', model => 'Base')).load;
        is-deeply $clone.load-branch-data(@vars, 'Branched')<fractions>,
            [1e0, 2e0, 3e0, 4e0, 5e0, 6e0], 'Cloned branch matrix matches source';
    }
```

- [ ] **Step 2: Run — verify FAIL (old clone zips dropped columns)**

```bash
export TMPDIR=/scratch/zaucker/tmp
PGPASSWORD=agrammon dropdb   -h localhost -p 55432 -U agrammon --if-exists branch_scratch
PGPASSWORD=agrammon createdb -h localhost -p 55432 -U agrammon branch_scratch
AGRAMMON_CFG=/scratch/zaucker/tmp/agrammon.scratch.cfg.yaml \
  raku -Ilib -It/lib t/dataset.rakutest 2>&1 | tail -20
```

Expected: the clone subtest FAILS.

- [ ] **Step 3: Replace the branch-clone block in `clone` (lines 256-290)**

Delete the three blocks ("get branched inputs from new dataset", "get branch data
from old dataset", the `for flat @data Z @rows` loop) and replace with a single
`INSERT ... SELECT` that remaps both vars by (instance name, var name):

```raku
            # clone branches: one self-describing row each, remapping row/col vars
            # to the new dataset's data rows by (instance name, var name).
            $db.query(q:to/SQL/, $ds<id>, $old-username, $old-dataset, $gui, $model, @versions);
                INSERT INTO branches (branches_row_var, branches_col_var,
                                      branches_row_options, branches_col_options, branches_matrix)
                SELECT nrv.data_id, ncv.data_id,
                       b.branches_row_options, b.branches_col_options, b.branches_matrix
                  FROM branches b
                  JOIN data orv ON (b.branches_row_var = orv.data_id)
                  JOIN data ocv ON (b.branches_col_var = ocv.data_id)
                  LEFT JOIN data_instance ori ON (orv.data_instance_id = ori.data_instance_id)
                  JOIN data_instance nri ON (nri.data_instance_dataset = $1
                                         AND nri.data_instance_name = ori.data_instance_name)
                  JOIN data nrv ON (nrv.data_dataset = $1 AND nrv.data_var = orv.data_var
                                AND nrv.data_instance_id = nri.data_instance_id)
                  JOIN data ncv ON (ncv.data_dataset = $1 AND ncv.data_var = ocv.data_var
                                AND ncv.data_instance_id = nri.data_instance_id)
                 WHERE orv.data_dataset = (
                       SELECT dataset_id FROM dataset
                        WHERE dataset_pers         = pers_email2id($2)
                          AND dataset_name         = $3
                          AND dataset_guivariant   = $4
                          AND dataset_modelvariant = $5
                          AND dataset_version      = ANY($6)
                        LIMIT 1)
            SQL
```

(Keep the surrounding `CATCH` and the data/instance clone steps above it unchanged.)

- [ ] **Step 4: Run — verify PASS**

```bash
export TMPDIR=/scratch/zaucker/tmp
PGPASSWORD=agrammon dropdb   -h localhost -p 55432 -U agrammon --if-exists branch_scratch
PGPASSWORD=agrammon createdb -h localhost -p 55432 -U agrammon branch_scratch
AGRAMMON_CFG=/scratch/zaucker/tmp/agrammon.scratch.cfg.yaml \
  raku -Ilib -It/lib t/dataset.rakutest 2>&1 | tail -20
```

Expected: clone subtest PASSES.

- [ ] **Step 5: Commit**

```bash
git add lib/Agrammon/DB/Dataset.rakumod t/dataset.rakutest
git commit -m "db(#421): clone branches via single-row INSERT...SELECT (task 3)"
```

---

## Task 5: Retire the per-variable `@branches` persistence

**Files:**
- Modify: `lib/Agrammon/DB/Dataset.rakumod:596-630` (`!store-instance-variable`)
- Modify: `t/dataset.rakutest:162-180` (`store-input() with branches`)

- [ ] **Step 1: Update the `store-input() with branches` test (lines 162-180)**

The matrix is no longer persisted per-variable; `store-input` with `branched`
value must still `lives-ok` (it stores the `data` row), and the non-instance guard
stays. Replace the subtest body:

```raku
    subtest 'store-input() with branches (per-variable persistence retired)' => {
        plan 2;
        # branch matrices are persisted via store-branch-data now; store-input
        # for a branched variable just records the data row and must not die.
        lives-ok {
            $dataset.store-input("my-multi-variable[Branch]::testB", 'branched')
        }, "Store branched instance variable (no inline branch persistence)";
        throws-like {
            $dataset.store-input(
                    "my-multi-variable::testB", 1,
                    [[0.2, 0.3], [0, 0.5]],
                    [[< deep_pit deep_litter >], [< less_than_twice_a_month twice_a_month >]])
        }, X::Agrammon::DB::Dataset::InvalidBranchData, "None-instance variable cannot have branch data";
    }
```

- [ ] **Step 2: Remove the inline branch INSERT from `!store-instance-variable` (lines 617-626)**

Delete the `if @branches { ... }` block so the method only stores the `data` row:

```raku
            # couldn't store variable
            die X::Agrammon::DB::Dataset::StoreDataFailed.new($variable) unless $ret.rows;

            return $ret.rows;
        }
    }
```

Leave `store-input`'s signature (`@branches?, @options?`) and the
`InvalidBranchData` guard for non-instance vars unchanged (lines 632-646).

- [ ] **Step 3: Run — verify PASS**

```bash
export TMPDIR=/scratch/zaucker/tmp
PGPASSWORD=agrammon dropdb   -h localhost -p 55432 -U agrammon --if-exists branch_scratch
PGPASSWORD=agrammon createdb -h localhost -p 55432 -U agrammon branch_scratch
AGRAMMON_CFG=/scratch/zaucker/tmp/agrammon.scratch.cfg.yaml \
  raku -Ilib -It/lib t/dataset.rakutest 2>&1 | tail -15
```

Expected: full `dataset.rakutest` PASSES.

- [ ] **Step 4: Commit**

```bash
git add lib/Agrammon/DB/Dataset.rakumod t/dataset.rakutest
git commit -m "db(#421): retire per-variable branch persistence (task 3)"
```

---

## Task 6: Frontend — pair-aware instance-copy branch write

**Files:**
- Modify: `frontend/source/class/agrammon/module/input/NavFolder.js:614-633` (`setDataset` storeAll loop)
- Modify: `frontend/source/class/agrammon/module/input/PropTable.js:538-560` (`__storeData`)

No automated test (Qooxdoo). Validation = `qx compile` clean + the user's GUI test.

- [ ] **Step 1: Make the `storeAll` loop pair-aware in `NavFolder.setDataset`**

In the `if (storeAll) { ... }` block (lines 614-633), skip the per-variable
`store_data` dispatch for branched variables and collect them; after the loop,
emit one `store_branch_data` for the pair. Replace the storeAll branch:

```javascript
        setDataset: function(newData, handleIgnore, storeAll) {
            var i;
            this.__propData = new Array;
            var len = newData.length;
            var noCheck = true;
            var data;
            var branchedVars = [];   // collect branched vars for a pair-aware save
            for (i=0; i<len; i++) {
                data = newData[i];
                var name = data.getName();
                var value = data.getValue();
                var comment = data.getComment();
                var meta = data.getMetaData();
                this.__propData.push(data);
                if (name.match(/_flattened/) && value === null) {
                    value = '';
                }
                if (storeAll) {
                    if (handleIgnore && name.match(/::ignore/)) {
                        this.setData(name, 'ignore', null, noCheck, null);
                        qx.event.message.Bus.dispatchByName('agrammon.PropTable.storeData',
                                                            { 'var': name, value: 'ignore' });
                    }
                    else if (value === 'branched') {
                        // branch matrices are persisted pair-aware below, not per
                        // variable (avoids the axis-blind per-variable write).
                        branchedVars.push({ name: name, meta: meta });
                        this.setData(name, value, comment, noCheck, meta.branches);
                    }
                    else {
                        qx.event.message.Bus.dispatchByName('agrammon.PropTable.storeData',
                                                            { 'var': name, value: value });
                        this.setData(name, value, comment, noCheck, meta.branches);
                    }
                }

                if (handleIgnore && name.match(/::ignore/)) {
                    this.setData(name, 'ignore', null, noCheck, null);
                    qx.event.message.Bus.dispatchByName('agrammon.PropTable.storeData',
                                                        { 'var': name, value: 'ignore' });
                }
            }
            if (storeAll && branchedVars.length === 2) {
                this.__storeBranchPair(branchedVars);
            }
```

- [ ] **Step 2: Add the `__storeBranchPair` helper to `NavFolder.js`**

Add this method to the `members` section (mirrors `BranchEditor.__storeBranchData`'s
payload: `vars[0]`=rows, `vars[1]`=cols; options keyed by var; `data` 2-D):

```javascript
        // Persist a branch pair via the pair-aware RPC (used on instance copy).
        __storeBranchPair: function(branchedVars) {
            var regex = /\[(.+)\]/;
            var rowVar = branchedVars[0], colVar = branchedVars[1];
            var m0 = regex.exec(rowVar.name);
            if (!m0) { return; }
            var instance = m0[1];
            var vars = [ rowVar.name.replace(regex, '[]'),
                         colVar.name.replace(regex, '[]') ];
            // option keys per variable (meta.options entries are [en,de,key] triples)
            var optionsOf = function(meta) {
                var keys = [];
                var opts = meta.options || [];
                for (var j=0; j<opts.length; j++) { keys.push(opts[j][2]); }
                return keys;
            };
            var options = {};
            options[vars[0]] = optionsOf(rowVar.meta);
            options[vars[1]] = optionsOf(colVar.meta);
            // meta.branches is the flat row-major matrix; reshape to rows x cols
            var nRows = options[vars[0]].length, nCols = options[vars[1]].length;
            var flat = rowVar.meta.branches || [];
            var matrix = [], n = 0;
            for (var r=0; r<nRows; r++) {
                var row = [];
                for (var c=0; c<nCols; c++) { row.push(Number(flat[n++]) || 0); }
                matrix.push(row);
            }
            var datasetName = '' + this.__info.getDatasetName();
            agrammon.io.remote.Rpc.getInstance().callAsyncSmart(
                function() {}, 'store_branch_data',
                { datasetName: datasetName,
                  data: { instance: instance, vars: vars, options: options, data: matrix } });
        },
```

> **Executor note:** confirm the RPC accessor used elsewhere in `NavFolder.js`
> (search for `callAsync`/`Rpc` in this file and reuse the exact same pattern/handle
> rather than the placeholder above; e.g. it may be `this.__rpc.callAsync(fn, 'store_branch_data', params)`). Also confirm `this.__info` is reachable in `NavFolder`; if not, obtain the dataset name the same way the surrounding storeData dispatch does.

- [ ] **Step 3: Drop the now-unused `branches`/`options` from `PropTable.__storeData`**

In `PropTable.js` `__storeData` (lines 538-560), remove `branches`/`options`:

```javascript
        __storeData: function(msg) {
            var data = msg.getData();
            var varName  = data['var'];
            var value    = data.value;
            if (value == '*** Select ***' || value == '***Select***') {
                return;
            }
            var datasetName = this.__info.getDatasetName();
            this.__rpc.callAsync(
                this.__store_data_func,
                'store_data',
                {
                    datasetName: datasetName,
                    variable:    varName,
                    value:       value
                }
            );
        },
```

- [ ] **Step 4: Compile the frontend (clean build check)**

```bash
cd frontend && npx qx compile --target=source --feedback=false 2>&1 | tail -20
```

Expected: compiles with no new errors referencing `NavFolder.js`/`PropTable.js`.

- [ ] **Step 5: Commit**

```bash
git add frontend/source/class/agrammon/module/input/NavFolder.js \
        frontend/source/class/agrammon/module/input/PropTable.js
git commit -m "frontend(#421): pair-aware branch write on instance copy (task 3)"
```

> ⚠️ **GUI test gate (user):** before pushing, the user verifies in the running
> GUI that (a) editing a branch matrix saves/reloads correctly, and (b) copying an
> instance that has a branch preserves the matrix. Requires the dev DB migrated
> (Task 7 note).

---

## Task 7: CI fixtures + dev DB migration note

**Files:**
- Modify: `t/test-data/agrammon.schema.sql`
- Modify: `t/test-data/agrammon_test.dump.sql`

- [ ] **Step 1: Regenerate `agrammon.schema.sql` via a scratch DB**

These files are not referenced by any `.rakutest` but build the GitHub/Drone CI
DBs, so they MUST carry the new branches shape. Regenerate from the committed file
+ migration (NOT from a live mutated DB), preserving each file's object set.

```bash
export TMPDIR=/scratch/zaucker/tmp
PGPASSWORD=agrammon dropdb   -h localhost -p 55432 -U agrammon --if-exists fixture_scratch
PGPASSWORD=agrammon createdb -h localhost -p 55432 -U agrammon fixture_scratch
PGPASSWORD=agrammon psql -h localhost -p 55432 -U agrammon -d fixture_scratch \
    -v ON_ERROR_STOP=1 -f t/test-data/agrammon.schema.sql
PGPASSWORD=agrammon psql -h localhost -p 55432 -U agrammon -d fixture_scratch \
    -v ON_ERROR_STOP=1 -f db/migrate-issue-421-branch-storage.sql
# dump only the branches table definition region and splice it back, OR (simpler)
# hand-edit agrammon.schema.sql's branches CREATE/constraints to match db/schema.sql.
```

Practical approach: **hand-edit** `t/test-data/agrammon.schema.sql` so its
`branches` `CREATE TABLE` + constraints + FK match the new `db/schema.sql` block
from Task 1 Step 3 (same columns, two UNIQUEs, two FKs, three CHECKs). Verify a
fresh load:

```bash
PGPASSWORD=agrammon dropdb   -h localhost -p 55432 -U agrammon --if-exists fixture_scratch
PGPASSWORD=agrammon createdb -h localhost -p 55432 -U agrammon fixture_scratch
PGPASSWORD=agrammon psql -h localhost -p 55432 -U agrammon -d fixture_scratch \
    -v ON_ERROR_STOP=1 -f t/test-data/agrammon.schema.sql && echo "schema fixture OK"
```

- [ ] **Step 2: Update `agrammon_test.dump.sql` branches region the same way**

Apply the identical branches `CREATE TABLE`/constraints/FK edits to
`t/test-data/agrammon_test.dump.sql` (it has fewer objects than schema.sql — only
edit the branches definition, do not add audit/login objects). If the dump
contains seeded `COPY public.branches ...` data, convert it to the new columns or
drop the seed rows (the dump is a role/skeleton seed; check before editing). Verify:

```bash
PGPASSWORD=agrammon dropdb   -h localhost -p 55432 -U agrammon --if-exists dump_scratch
PGPASSWORD=agrammon createdb -h localhost -p 55432 -U agrammon dump_scratch
PGPASSWORD=agrammon psql -h localhost -p 55432 -U agrammon -d dump_scratch \
    -v ON_ERROR_STOP=1 -f t/test-data/agrammon_test.dump.sql && echo "dump fixture OK"
```

- [ ] **Step 3: Commit**

```bash
git add t/test-data/agrammon.schema.sql t/test-data/agrammon_test.dump.sql
git commit -m "test(#421): branches single-row shape in CI fixtures (task 3)"
```

- [ ] **Step 4: Document the dev/test DB migration (for the user, not autonomous)**

Do NOT run this autonomously (DROP COLUMN needs the user's OK). Record the command
for the user to run before GUI testing, against the **dev** DB the GUI uses
(`:55433`) and, when ready, the **test** DB (`:55432`):

```bash
# dev DB (GUI) — run when the user is present:
PGPASSWORD=agrammon psql -h localhost -p 55433 -U agrammon -d <dev-db> \
    -f db/migrate-issue-421-branch-storage.sql
# test DB:
PGPASSWORD=agrammon psql -h localhost -p 55432 -U agrammon -d agrammon_test \
    -f db/migrate-issue-421-branch-storage.sql
```

---

## Task 8: Full verification

- [ ] **Step 1: Run the whole DB-integration suite against a fresh scratch DB**

```bash
export TMPDIR=/scratch/zaucker/tmp
PGPASSWORD=agrammon dropdb   -h localhost -p 55432 -U agrammon --if-exists branch_scratch
PGPASSWORD=agrammon createdb -h localhost -p 55432 -U agrammon branch_scratch
AGRAMMON_CFG=/scratch/zaucker/tmp/agrammon.scratch.cfg.yaml \
  prove6 -Ilib -It/lib t/ 2>&1 | tail -30
```

Expected: full suite green (or only pre-existing unrelated failures noted in memory).

- [ ] **Step 2: Run the unit-test subset (no DB)**

```bash
AGRAMMON_UNIT_TEST=1 prove6 -l t/inputs-branching.rakutest t/model.rakutest 2>&1 | tail -10
```

Expected: green (`inputs-branching` is storage-agnostic and must be unaffected).

- [ ] **Step 3: Self-review the diff**

```bash
git log --oneline main..HEAD
git diff --stat main..HEAD
```

Confirm: no leftover references to `branches_var` / `branches_data` /
`branches_options` (old columns) in `lib/`:

```bash
grep -rn "branches_var\|branches_data\|branches_options" lib/ && echo "FOUND OLD REFS — fix" || echo "clean"
```

Expected: `clean`.

---

## Self-Review (author)

- **Spec coverage:** schema (Task 1), migration (Task 1), read (Task 2), store/load
  (Task 3), clone (Task 4), retire per-variable write (Task 5), frontend pair-aware
  write (Task 6), CI fixtures + dev DB note (Task 7), verification (Task 8). All spec
  sections mapped.
- **Type/name consistency:** new columns `branches_row_var`, `branches_col_var`,
  `branches_row_options`, `branches_col_options`, `branches_matrix` used uniformly
  across migration, schema.sql, AgrammonTest, read, store/load, clone, fixtures.
  `store-branch-data` reads `vars[0]`=row / `vars[1]`=col; `load-branch-data` looks
  up by `vars[0]`; read joins `branches_row_var`→`rv`, `branches_col_var`→`cv`.
- **Open executor confirmations (flagged inline):** the exact RPC handle in
  `NavFolder.__storeBranchPair` (Task 6 Step 2) and whether the `agrammon_test.dump.sql`
  carries `COPY branches` seed rows (Task 7 Step 2).
