# data_instance Table Implementation Plan (#421 task 2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Normalize the per-instance properties (name + display order) out of the `data` table into a dedicated `data_instance` table referenced by a foreign key, with `data_view` joining the two — keeping all user-facing behavior identical.

**Architecture:** A new `data_instance(id, dataset, name, order)` table. `data` gains `data_instance_id` (FK, `ON DELETE CASCADE`) and loses `data_instance` / `data_instance_order`. Writes get-or-create the instance row; `data_view` rebuilds the `[name]` substitution via a `LEFT JOIN`. Instance rename/reorder/delete become single-row operations.

**Tech Stack:** Raku, PostgreSQL (DB::Pg), Cro. Tests are `.rakutest` run against the podman test DB (`agrammon_test` on :55432) with `AGRAMMON_CFG=t/test-data/agrammon.cfg.yaml`.

**Branch:** `refactor/issue-421-instance-table`, stacked on `refactor/issue-421-rename-data-table` (task 1). Spec: `docs/superpowers/specs/2026-06-17-data-instance-table-design.md`.

**Testing notes:**
- DB tests skip under `AGRAMMON_UNIT_TEST`; run them with `AGRAMMON_CFG=t/test-data/agrammon.cfg.yaml raku -Ilib -It/lib t/<file>.rakutest`.
- The existing `t/datasource-db.rakutest` (22) and `t/dataset.rakutest` (16) are the behavior-preservation safety net. New tests are added in Task 9.
- The test DB currently has task-1's `data` table; this plan migrates it once (Task 2) so tests see the new schema.

---

### Task 1: Update inline test schema (helpers)

The two inline `CREATE TABLE data` definitions used by DB tests must describe the new schema before any code change, or every DB test fails to set up.

**Files:**
- Modify: `t/lib/AgrammonTest.rakumod` (the `prepare-test-db` schema + seed inserts, ~lines 58-99)
- Modify: `t/datasource-db.rakutest` (inline schema ~lines 406-420; seed inserts at ~246, 275, 306, 351)

- [ ] **Step 1: Rewrite the `data`/`data_instance` schema in `AgrammonTest.rakumod`**

Replace the `CREATE TABLE IF NOT EXISTS data (...)` block (currently lines 59-67) with a `data_instance` table plus the new `data`:

```raku
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
```

- [ ] **Step 2: Update the seed inserts in `AgrammonTest.rakumod` to use the instance table**

The seed (lines 89-93) inserts instance rows directly. Insert a `data_instance` row, then reference it:

```raku
    $db.query(q:to/SQL/);
    INSERT INTO data_instance (data_instance_id, data_instance_dataset, data_instance_name)
                       VALUES (-91000, -42000, 'Branched')
    SQL

    $db.query(q:to/SQL/);
    INSERT INTO data (data_id, data_dataset, data_var, data_instance_id, data_val)
                 VALUES (-76315980, -42000, 'Livestock::Poultry[]::Housing::Type::housing_type',            -91000, 'branched'),
                        (-76315982, -42000, 'Livestock::Poultry[]::Housing::Type::manure_removal_interval', -91000, 'branched')
    SQL
```

(The `branches` seed at lines 96-99 is unchanged — it references `data_id`.)

- [ ] **Step 3: Rewrite the inline schema + seeds in `datasource-db.rakutest`**

Apply the same `data_instance` + `data` schema as Step 1 to the inline `CREATE TABLE` (~line 406). For each seed `INSERT INTO data (... data_instance ...)` (lines ~306, 351 use `data_instance`), first insert a `data_instance` row for that dataset+name and use `data_instance_id`. The two single-instance inserts (lines ~246, 275) have no `data_instance` column → only change is the table already matches (no instance). Show the branched-data block (line ~306) converted:

```raku
    # before: INSERT INTO data (data_dataset, data_instance, data_var, data_val) VALUES (..., 'InstanceName', ...)
    # after:
    $db.query(q:to/SQL/);
    INSERT INTO data_instance (data_instance_id, data_instance_dataset, data_instance_name)
                       VALUES (<neg-id>, <dataset-id>, 'InstanceName')
    SQL
    $db.query(q:to/SQL/);
    INSERT INTO data (data_dataset, data_instance_id, data_var, data_val)
                 VALUES (<dataset-id>, <neg-id>, '...', '...')
    SQL
```

Use distinct negative ids per instance to stay clear of real sequence values, matching the file's existing convention.

- [ ] **Step 4: Commit**

```bash
git add t/lib/AgrammonTest.rakumod t/datasource-db.rakutest
git commit -m "test(#421): inline test schema uses data_instance table"
```

---

### Task 2: schema.sql + migration script

**Files:**
- Modify: `db/schema.sql`
- Create: `db/migrate-issue-421-data-instance-table.sql`

- [ ] **Step 1: Add `data_instance` to `db/schema.sql`**

Add the table definition (place it near the `data` table). Mirror the existing sequence/ownership style used by `data`:

```sql
CREATE TABLE public.data_instance (
    data_instance_id      integer NOT NULL,
    data_instance_dataset integer NOT NULL,
    data_instance_name    text NOT NULL,
    data_instance_order   integer
);
ALTER TABLE public.data_instance OWNER TO agrammon;

CREATE SEQUENCE public.data_instance_data_instance_id_seq
    AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
ALTER TABLE public.data_instance_data_instance_id_seq OWNER TO agrammon;
ALTER SEQUENCE public.data_instance_data_instance_id_seq OWNED BY public.data_instance.data_instance_id;
ALTER TABLE ONLY public.data_instance
    ALTER COLUMN data_instance_id SET DEFAULT nextval('public.data_instance_data_instance_id_seq'::regclass);

ALTER TABLE ONLY public.data_instance
    ADD CONSTRAINT data_instance_pkey PRIMARY KEY (data_instance_id);
ALTER TABLE ONLY public.data_instance
    ADD CONSTRAINT data_instance_dataset_name_key UNIQUE (data_instance_dataset, data_instance_name);
ALTER TABLE ONLY public.data_instance
    ADD CONSTRAINT data_instance_dataset_fkey FOREIGN KEY (data_instance_dataset)
        REFERENCES public.dataset(dataset_id) ON DELETE CASCADE;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.data_instance TO agrammon_user;
GRANT SELECT,UPDATE ON SEQUENCE public.data_instance_data_instance_id_seq TO agrammon_user;
```

- [ ] **Step 2: Modify the `data` table in `db/schema.sql`**

Remove columns `data_instance text` and `data_instance_order integer`; add `data_instance_id integer`. Replace the unique constraint:

```sql
-- in CREATE TABLE public.data (...): drop data_instance, data_instance_order; add:
    data_instance_id integer
-- replace:
--   ADD CONSTRAINT data_data_var_key UNIQUE (data_var, data_instance, data_dataset);
-- with:
    ADD CONSTRAINT data_data_var_key UNIQUE (data_var, data_instance_id, data_dataset);
-- add FK:
ALTER TABLE ONLY public.data
    ADD CONSTRAINT data_data_instance_id_fkey FOREIGN KEY (data_instance_id)
        REFERENCES public.data_instance(data_instance_id) ON DELETE CASCADE;
```

- [ ] **Step 3: Replace the `data_view` definition in `db/schema.sql`**

```sql
CREATE VIEW public.data_view AS
 SELECT d.data_id,
    d.data_dataset,
    COALESCE(replace(d.data_var, '[]'::text, (('['::text || i.data_instance_name) || ']'::text)), d.data_var) AS data_var,
    d.data_val,
    i.data_instance_order,
    d.data_comment
   FROM (public.data d
     LEFT JOIN public.data_instance i ON ((d.data_instance_id = i.data_instance_id)))
  ORDER BY d.data_dataset, COALESCE(replace(d.data_var, '[]'::text, (('['::text || i.data_instance_name) || ']'::text)), d.data_var);
ALTER TABLE public.data_view OWNER TO agrammon;
GRANT SELECT ON TABLE public.data_view TO agrammon_user;
```

- [ ] **Step 4: Write the migration script**

Create `db/migrate-issue-421-data-instance-table.sql`:

```sql
-- Issue #421 (task 2): normalize the per-instance name + order out of `data`
-- into a `data_instance` table. Run once per deployment, AFTER
-- db/migrate-issue-421-rename-data-new-to-data.sql. Atomic.
BEGIN;

CREATE TABLE public.data_instance (
    data_instance_id      integer NOT NULL,
    data_instance_dataset integer NOT NULL REFERENCES public.dataset(dataset_id) ON DELETE CASCADE,
    data_instance_name    text NOT NULL,
    data_instance_order   integer
);
CREATE SEQUENCE public.data_instance_data_instance_id_seq
    AS integer START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
ALTER SEQUENCE public.data_instance_data_instance_id_seq OWNED BY public.data_instance.data_instance_id;
ALTER TABLE ONLY public.data_instance
    ALTER COLUMN data_instance_id SET DEFAULT nextval('public.data_instance_data_instance_id_seq'::regclass);
ALTER TABLE ONLY public.data_instance ADD CONSTRAINT data_instance_pkey PRIMARY KEY (data_instance_id);
ALTER TABLE ONLY public.data_instance ADD CONSTRAINT data_instance_dataset_name_key UNIQUE (data_instance_dataset, data_instance_name);
ALTER TABLE public.data_instance OWNER TO agrammon;
ALTER TABLE public.data_instance_data_instance_id_seq OWNER TO agrammon;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.data_instance TO agrammon_user;
GRANT SELECT,UPDATE ON SEQUENCE public.data_instance_data_instance_id_seq TO agrammon_user;

-- backfill one row per (dataset, instance); GROUP BY collapses any order drift
INSERT INTO public.data_instance (data_instance_dataset, data_instance_name, data_instance_order)
     SELECT data_dataset, data_instance, MAX(data_instance_order)
       FROM public.data
      WHERE data_instance IS NOT NULL
   GROUP BY data_dataset, data_instance;

ALTER TABLE public.data ADD COLUMN data_instance_id integer;
UPDATE public.data d
   SET data_instance_id = i.data_instance_id
  FROM public.data_instance i
 WHERE d.data_dataset  = i.data_instance_dataset
   AND d.data_instance = i.data_instance_name;

DROP VIEW public.data_view;
ALTER TABLE public.data DROP CONSTRAINT data_data_var_key;
ALTER TABLE public.data DROP COLUMN data_instance;
ALTER TABLE public.data DROP COLUMN data_instance_order;
ALTER TABLE public.data ADD CONSTRAINT data_data_var_key UNIQUE (data_var, data_instance_id, data_dataset);
ALTER TABLE ONLY public.data ADD CONSTRAINT data_data_instance_id_fkey
    FOREIGN KEY (data_instance_id) REFERENCES public.data_instance(data_instance_id) ON DELETE CASCADE;

CREATE VIEW public.data_view AS
 SELECT d.data_id, d.data_dataset,
    COALESCE(replace(d.data_var, '[]'::text, (('['::text || i.data_instance_name) || ']'::text)), d.data_var) AS data_var,
    d.data_val, i.data_instance_order, d.data_comment
   FROM (public.data d LEFT JOIN public.data_instance i ON ((d.data_instance_id = i.data_instance_id)))
  ORDER BY d.data_dataset, COALESCE(replace(d.data_var, '[]'::text, (('['::text || i.data_instance_name) || ']'::text)), d.data_var);
ALTER TABLE public.data_view OWNER TO agrammon;
GRANT SELECT ON TABLE public.data_view TO agrammon_user;

COMMIT;
```

- [ ] **Step 5: Apply the migration to the test DB and sanity-check**

```bash
podman exec -i agrammon-postgres psql -U agrammon -d agrammon_test -v ON_ERROR_STOP=1 \
  < db/migrate-issue-421-data-instance-table.sql
podman exec agrammon-postgres psql -U agrammon -d agrammon_test -tAc \
  "SELECT count(*) FROM data_instance; SELECT pg_get_viewdef('public.data_view'::regclass);"
```
Expected: migration prints `BEGIN … COMMIT`; `data_view` def shows the join on `data_instance`.

- [ ] **Step 6: Commit**

```bash
git add db/schema.sql db/migrate-issue-421-data-instance-table.sql
git commit -m "db(#421): data_instance table — schema + migration"
```

---

### Task 3: `DataSource::DB.read` — join for the instance name

**Files:**
- Modify: `lib/Agrammon/DataSource/DB.rakumod:28-38`

- [ ] **Step 1: Update the SELECT to join `data_instance`**

```raku
            my $results = $db.query(q:to/STATEMENT/, $user, $dataset, %variant<version>, %variant<gui>, %variant<model>);
                SELECT data_var, data_val, i.data_instance_name,
                       branches_data, branches_options,
                       data_comment
                FROM data
                LEFT JOIN data_instance i ON (data.data_instance_id = i.data_instance_id)
                LEFT JOIN branches ON (data_id=branches_var)
                WHERE data_dataset=dataset_name2id($1,$2,$3,$4,$5)
                    AND data_var not like '%ignore'
                ORDER BY i.data_instance_name, branches_var, data_var, data_val
            STATEMENT
```

The result shape is unchanged (column 2 is still the instance name, `// ''` downstream at line 51).

- [ ] **Step 2: Run the model-run-from-DB test**

Run: `AGRAMMON_CFG=t/test-data/agrammon.cfg.yaml raku -Ilib -It/lib t/datasource-db.rakutest`
Expected: PASS (22 subtests) — this is the primary consumer of `DataSource::DB.read`.

- [ ] **Step 3: Commit**

```bash
git add lib/Agrammon/DataSource/DB.rakumod
git commit -m "db(#421): DataSource::DB.read joins data_instance for the name"
```

---

### Task 4: get-or-create helper + instance writes

**Files:**
- Modify: `lib/Agrammon/DB/Dataset.rakumod` (`!store-instance-variable` ~560, `!store-instance-variable-comment` ~482; add helper)

- [ ] **Step 1: Add the get-or-create helper**

Add near the other private methods:

```raku
    method !instance-id($db, $username, $instance) {
        my $ret = $db.query(q:to/SQL/, $username, $!name, |self!variant, $instance);
            INSERT INTO data_instance (data_instance_dataset, data_instance_name)
                 VALUES (dataset_name2id($1,$2,$3,$4,$5), $6)
            ON CONFLICT (data_instance_dataset, data_instance_name) DO
                 UPDATE SET data_instance_name = EXCLUDED.data_instance_name
            RETURNING data_instance_id
        SQL
        return $ret.value;
    }
```

(The no-op `DO UPDATE` is deliberate: `DO NOTHING` would not `RETURNING` on an existing row.)

- [ ] **Step 2: Rewrite `!store-instance-variable`**

```raku
    method !store-instance-variable($variable, $instance, $value, @branches?, @options?) {
        my $username = $!user.username;

        self.with-db: -> $db {
            my $instance-id = self!instance-id($db, $username, $instance);

            my $ret = $db.query(q:to/SQL/, $value, $instance-id, $variable);
                UPDATE data SET data_val = $1
                 WHERE data_instance_id = $2 AND data_var = $3
                RETURNING data_id
            SQL

            $ret = $db.query(q:to/SQL/, $value, $instance-id, $variable) unless $ret.rows;
                INSERT INTO data (data_dataset, data_var, data_val, data_instance_id)
                     VALUES ((SELECT data_instance_dataset FROM data_instance WHERE data_instance_id = $2), $3, $1, $2)
                RETURNING data_id
            SQL

            # couldn't store variable
            die X::Agrammon::DB::Dataset::StoreDataFailed.new($variable) unless $ret.rows;

            if @branches {
                my $data-id = $ret.value;
                $ret = $db.query(q:to/SQL/, $data-id, @branches[*;*], @options);
                    INSERT INTO branches (branches_var, branches_data, branches_options)
                         VALUES ($1, $2, $3)
                    RETURNING branches_id
                SQL
                die X::Agrammon::DB::Dataset::StoreBranchDataFailed.new($variable) unless $ret.rows;
            }
            return $ret.rows;
        }
    }
```

- [ ] **Step 3: Rewrite `!store-instance-variable-comment`**

```raku
    method !store-instance-variable-comment($variable, $instance, $comment) {
        my $username = $!user.username;

        self.with-db: -> $db {
            my $instance-id = self!instance-id($db, $username, $instance);

            my $ret = $db.query(q:to/SQL/, $comment, $instance-id, $variable);
                UPDATE data SET data_comment = $1
                 WHERE data_instance_id = $2 AND data_var = $3
                RETURNING data_comment
            SQL
            return $ret.rows if $ret.rows;

            $ret = $db.query(q:to/SQL/, $comment, $instance-id, $variable);
                INSERT INTO data (data_dataset, data_var, data_comment, data_instance_id)
                     VALUES ((SELECT data_instance_dataset FROM data_instance WHERE data_instance_id = $2), $3, $1, $2)
                RETURNING data_comment
            SQL

            die X::Agrammon::DB::Dataset::StoreInputCommentFailed.new(:$comment, :$variable) unless $ret.rows;

            $db.query(q:to/SQL/, $!user.username, $!name, |self!variant);
                    UPDATE dataset SET dataset_mod_date = CURRENT_TIMESTAMP
                     WHERE dataset_id=dataset_name2id($1,$2,$3,$4,$5)
            SQL
            return $ret.rows;
        }
    }
```

(`!store-variable` and `!store-variable-comment` — the non-instance paths — are unchanged: they insert with `data_instance_id` left NULL by omission.)

- [ ] **Step 4: Run the dataset CRUD test**

Run: `AGRAMMON_CFG=t/test-data/agrammon.cfg.yaml raku -Ilib -It/lib t/dataset.rakutest`
Expected: PASS (store/load round-trips, branch store/load all green).

- [ ] **Step 5: Commit**

```bash
git add lib/Agrammon/DB/Dataset.rakumod
git commit -m "db(#421): instance writes via get-or-create instance id"
```

---

### Task 5: rename / reorder / delete instance — single-row ops

**Files:**
- Modify: `lib/Agrammon/DB/Dataset.rakumod` (`delete-instance` ~688, `rename-instance` ~704, `order-instances` ~732)

- [ ] **Step 1: Rewrite `delete-instance`**

```raku
    method delete-instance($variable-pattern, $instance --> Nil) {
        # $variable-pattern is retained for API compatibility but no longer
        # needed: deleting the instance row cascades to all its data rows.
        my $username = $!user.username;
        self.with-db: -> $db {
            my $ret = $db.query(q:to/SQL/, $username, $!name, |self!variant, $instance);
                DELETE FROM data_instance
                 WHERE data_instance_dataset = dataset_name2id($1,$2,$3,$4,$5)
                   AND data_instance_name = $6
                RETURNING data_instance_id
            SQL
            die X::Agrammon::DB::Dataset::InstanceDeleteFailed.new(:$instance) unless $ret.rows;
        }
    }
```

- [ ] **Step 2: Rewrite `rename-instance`**

```raku
    method rename-instance($old-name, $new-name, $pattern --> Nil) {
        # $pattern is retained for API compatibility; the instance name is
        # unique per dataset so a single row is renamed.
        my $username = $!user.username;
        self.with-db: -> $db {
            die X::Agrammon::DB::Dataset::InstanceRenameFailed.new(:$old-name, :$new-name) if $old-name eq $new-name;

            my $ret = $db.query(q:to/SQL/, $new-name, $username, $!name, |self!variant, $old-name);
                UPDATE data_instance SET data_instance_name = $1
                 WHERE data_instance_dataset = dataset_name2id($2,$3,$4,$5,$6)
                   AND data_instance_name = $7
                RETURNING data_instance_id
            SQL

            CATCH {
                .note;
                when /unique/ {
                    die X::Agrammon::DB::Dataset::InstanceAlreadyExists.new(:name($new-name));
                }
            }
            die X::Agrammon::DB::Dataset::InstanceRenameFailed.new(:$old-name, :$new-name) unless $ret.rows;
        }
    }
```

- [ ] **Step 3: Rewrite `order-instances`**

```raku
    method order-instances(@instances) {
        my $username = $!user.username;
        self.with-db: -> $db {
            for @instances.kv -> $i, $pattern {
                $pattern ~~ / (.+) '[' (.+) ']' /;
                my $instance = $1;
                $db.query(q:to/SQL/, $i, $username, $!name, |self!variant, $instance);
                UPDATE data_instance SET data_instance_order = $1
                 WHERE data_instance_dataset = dataset_name2id($2,$3,$4,$5,$6)
                   AND data_instance_name = $7
                RETURNING data_instance_order
                SQL
            }
        }
        CATCH {
            .note;
            die X::Agrammon::DB::Dataset::InstanceReorderFailed.new(:$!name);
        }
    }
```

- [ ] **Step 4: Run the dataset test**

Run: `AGRAMMON_CFG=t/test-data/agrammon.cfg.yaml raku -Ilib -It/lib t/dataset.rakutest`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/Agrammon/DB/Dataset.rakumod
git commit -m "db(#421): rename/reorder/delete instance as single-row ops"
```

---

### Task 6: branch-data instance filtering

**Files:**
- Modify: `lib/Agrammon/DB/Dataset.rakumod` (`store-branch-data` ~758, `load-branch-data` ~801)

- [ ] **Step 1: Update the var-id lookup in `store-branch-data`**

Replace the `AND data_instance = $8` filter (the `SELECT data_id, data_var FROM data … WHERE … data_instance = $8`) with an instance-id subquery:

```raku
            @branch-variables = $db.query(q:to/SQL/, $username, $dataset-name, |self!variant, |@vars, $instance).hashes;
            SELECT data_id, data_var
                  FROM data
                 WHERE data_dataset=dataset_name2id($1,$2,$3,$4,$5)
                   AND data_var IN ($6,$7)
                   AND data_instance_id = (SELECT data_instance_id FROM data_instance
                                            WHERE data_instance_dataset = dataset_name2id($1,$2,$3,$4,$5)
                                              AND data_instance_name = $8)
                   ORDER BY data_id
            SQL
```

- [ ] **Step 2: Update the var-id lookup in `load-branch-data`** (same transformation)

```raku
            my @vars = $db.query(q:to/SQL/, $username, $!name, |self!variant, |@var-names, $instance).arrays;
                SELECT data_id
                  FROM data
                 WHERE data_dataset=dataset_name2id($1,$2,$3,$4,$5)
                   AND data_var IN ($6,$7)
                   AND data_instance_id = (SELECT data_instance_id FROM data_instance
                                            WHERE data_instance_dataset = dataset_name2id($1,$2,$3,$4,$5)
                                              AND data_instance_name = $8)
                 ORDER BY data_id
            SQL
```

- [ ] **Step 3: Run the branch round-trip tests**

Run: `AGRAMMON_CFG=t/test-data/agrammon.cfg.yaml raku -Ilib -It/lib t/dataset.rakutest`
and `… t/datasource-db.rakutest`
Expected: PASS (both — branch store/load covered in dataset.rakutest; branched-data read in datasource-db.rakutest).

- [ ] **Step 4: Commit**

```bash
git add lib/Agrammon/DB/Dataset.rakumod
git commit -m "db(#421): branch-data filters by instance id"
```

---

### Task 7: clone — copy instances then remap

**Files:**
- Modify: `lib/Agrammon/DB/Dataset.rakumod` (`clone` ~219-260)

- [ ] **Step 1: Copy the source dataset's instance rows, then the data rows remapped**

Replace the single `INSERT INTO data … SELECT … FROM data` (lines 221-234) with a two-step copy. `$ds<id>` is the new dataset id; the inner `SELECT dataset_id …` is the old dataset.

```raku
            # clone instances of the source dataset into the new dataset
            $db.query(q:to/SQL/, $ds<id>, $old-username, $old-dataset, $gui, $model, @versions);
                INSERT INTO data_instance (data_instance_dataset, data_instance_name, data_instance_order)
                     SELECT $1, data_instance_name, data_instance_order
                       FROM data_instance
                      WHERE data_instance_dataset = (
                          SELECT dataset_id FROM dataset
                           WHERE dataset_pers = pers_email2id($2) AND dataset_name = $3
                             AND dataset_guivariant = $4 AND dataset_modelvariant = $5
                             AND dataset_version = ANY($6) LIMIT 1)
            SQL

            # clone inputs, remapping each row's instance id by (dataset, name)
            $db.query(q:to/SQL/, $ds<id>, $old-username, $old-dataset, $gui, $model, @versions);
                INSERT INTO data (data_dataset, data_var, data_val, data_instance_id, data_comment)
                     SELECT $1, d.data_var, d.data_val, ni.data_instance_id, d.data_comment
                       FROM data d
                       LEFT JOIN data_instance oi ON (d.data_instance_id = oi.data_instance_id)
                       LEFT JOIN data_instance ni ON (ni.data_instance_dataset = $1
                                                  AND ni.data_instance_name = oi.data_instance_name)
                      WHERE d.data_dataset = (
                          SELECT dataset_id FROM dataset
                           WHERE dataset_pers = pers_email2id($2) AND dataset_name = $3
                             AND dataset_guivariant = $4 AND dataset_modelvariant = $5
                             AND dataset_version = ANY($6) LIMIT 1)
            SQL
```

- [ ] **Step 2: Fix the branch-clone ordering joins**

The two branch-clone queries order by `data_instance` (lines 242, 259) to zip rows. Join `data_instance` and order by name. For the new-dataset query (line 237-243):

```raku
            my @rows = $db.query(q:to/SQL/, $ds<id>).arrays;
            SELECT data_id
              FROM data
              LEFT JOIN data_instance ON (data.data_instance_id = data_instance.data_instance_id)
              LEFT JOIN branches ON (branches_var=data_id)
             WHERE data_dataset=$1
               AND data_val = 'branched'
             ORDER BY data_instance_name, data_id -- don't change sort order!!!
            SQL
```

For the old-dataset query (line 246-260) add the same `LEFT JOIN data_instance` and change `ORDER BY data_instance, data_id` to `ORDER BY data_instance_name, data_id`.

- [ ] **Step 3: Run the clone test**

Run: `AGRAMMON_CFG=t/test-data/agrammon.cfg.yaml raku -Ilib -It/lib t/webservice.rakutest`
Expected: the `clone-dataset` subtest passes (the existing 2 pre-existing unrelated failures — `get-cfg()`, model input-variable key-set — remain; no NEW failures).
Also run `… t/dataset.rakutest` → PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/Agrammon/DB/Dataset.rakumod
git commit -m "db(#421): clone copies instances and remaps instance ids"
```

---

### Task 8: regenerate pg_dump fixtures + full suite

**Files:**
- Modify: `t/test-data/agrammon.schema.sql`, `t/test-data/agrammon_test.dump.sql`

- [ ] **Step 1: Regenerate the schema + data dumps from the migrated test DB**

```bash
podman exec agrammon-postgres pg_dump -U agrammon -d agrammon_test --schema-only --no-owner=false \
  > /tmp/new.schema.sql
podman exec agrammon-postgres pg_dump -U agrammon -d agrammon_test \
  > /tmp/new.dump.sql
```
Compare against the committed fixtures to confirm only the intended structural delta (new `data_instance` table + FK + dropped columns + new view) differs, then copy into place:

```bash
diff <(git show HEAD:t/test-data/agrammon.schema.sql) /tmp/new.schema.sql | head -80   # review
cp /tmp/new.schema.sql  t/test-data/agrammon.schema.sql
cp /tmp/new.dump.sql     t/test-data/agrammon_test.dump.sql
```
Expected: the diff shows the `data_instance` table/sequence/constraints, `data` losing `data_instance`/`data_instance_order` and gaining `data_instance_id`, and the rewritten `data_view` — nothing unrelated. If the dumps carry environment-specific noise (extension/version comment lines), keep the committed file's header and splice only the structural sections; review the diff to confirm.

- [ ] **Step 2: Run the full suite against the test DB**

Run: `AGRAMMON_CFG=t/test-data/agrammon.cfg.yaml prove6 -Ilib -It/lib t/`
Expected: same result as the task-1 baseline — all green except the 2 pre-existing `webservice` failures (`get-cfg()`, model input-variable key-set). No new failures.

- [ ] **Step 3: Commit**

```bash
git add t/test-data/agrammon.schema.sql t/test-data/agrammon_test.dump.sql
git commit -m "test(#421): regenerate fixtures with data_instance table"
```

---

### Task 9: new round-trip tests for the normalization guarantees

**Files:**
- Modify: `t/dataset.rakutest` (add subtests)

These assert the *new* invariants the normalization provides, beyond the behavior-preservation the existing tests already cover.

- [ ] **Step 1: Add a "rename touches exactly one instance row" test**

Add a subtest that, against a seeded dataset with an instance carrying several variables: calls `rename-instance`, then queries `data_instance` directly and asserts exactly one row changed name and the variable count under the instance is unchanged.

```raku
subtest 'rename-instance updates one data_instance row, data rows untouched' => {
    my $ds = Agrammon::DB::Dataset.new(:$user, name => 'BranchTest');
    # seed: store two instance vars under 'Grp A'
    $ds.store-input('Livestock::Poultry[Grp A]::Housing::Type::housing_type', 'x');
    $ds.store-input('Livestock::Poultry[Grp A]::Housing::Type::manure_removal_interval', 'y');
    $ds.rename-instance('Grp A', 'Grp B', 'Livestock::Poultry[]');
    my $rows = $ds.with-db: -> $db {
        $db.query(q:to/SQL/, 'Grp B').hash;
            SELECT (SELECT count(*) FROM data_instance WHERE data_instance_name = $1) AS inst,
                   (SELECT count(*) FROM data d JOIN data_instance i ON d.data_instance_id=i.data_instance_id
                      WHERE i.data_instance_name = $1) AS vars
        SQL
    };
    is $rows<inst>, 1, 'exactly one instance row carries the new name';
    is $rows<vars>, 2, 'both variables still resolve under the renamed instance';
}
```

Adapt the exact `Agrammon::DB::Dataset` construction + `with-db` access to match the patterns already used in `t/dataset.rakutest` (read the file's existing subtests first and mirror them).

- [ ] **Step 2: Add a "delete-instance cascades" test**

After seeding an instance with variables, call `delete-instance`, then assert both the `data_instance` row and its `data` rows are gone:

```raku
subtest 'delete-instance removes the instance row and cascades data rows' => {
    my $ds = Agrammon::DB::Dataset.new(:$user, name => 'BranchTest');
    $ds.store-input('Livestock::Poultry[Grp C]::Housing::Type::housing_type', 'x');
    $ds.delete-instance('Livestock::Poultry[]', 'Grp C');
    my %c = $ds.with-db: -> $db {
        $db.query(q:to/SQL/, 'Grp C').hash;
            SELECT (SELECT count(*) FROM data_instance WHERE data_instance_name=$1) AS inst,
                   (SELECT count(*) FROM data d JOIN data_instance i ON d.data_instance_id=i.data_instance_id
                      WHERE i.data_instance_name=$1) AS vars
        SQL
    };
    is %c<inst>, 0, 'instance row deleted';
    is %c<vars>, 0, 'data rows cascade-deleted';
}
```

- [ ] **Step 3: Add a "clone copies instances with distinct ids" test**

Clone a dataset that has an instance; assert the clone has its own `data_instance` row (different id, same name) and the cloned data rows point at it.

```raku
subtest 'clone duplicates instances under new ids' => {
    # clone BranchTest -> BranchTestClone via the existing clone API used in the file,
    # then assert the two datasets reference different data_instance_id values
    # for the same instance name, and the clone's data rows resolve to its own instance.
}
```
Fill the body using the clone invocation pattern already present in `t/webservice.rakutest`/`t/dataset.rakutest`; assert `data_instance_id` differs between original and clone for the same `data_instance_name`, and that `data_view` for the clone reproduces the `[name]` substitution.

- [ ] **Step 4: Run the new tests**

Run: `AGRAMMON_CFG=t/test-data/agrammon.cfg.yaml raku -Ilib -It/lib t/dataset.rakutest`
Expected: PASS including the three new subtests.

- [ ] **Step 5: Commit**

```bash
git add t/dataset.rakutest
git commit -m "test(#421): round-trip tests for data_instance rename/delete/clone"
```

---

### Task 10: final verification

- [ ] **Step 1: Full suite green (except known pre-existing)**

Run: `AGRAMMON_CFG=t/test-data/agrammon.cfg.yaml prove6 -Ilib -It/lib t/`
Expected: all green except the 2 pre-existing `webservice` failures documented in task 1.

- [ ] **Step 2: Unit-only suite still green**

Run: `AGRAMMON_UNIT_TEST=1 prove6 -Ilib t/`
Expected: all green (non-DB tests unaffected).

- [ ] **Step 3: Push + open PR** (after user confirms)

```bash
git push -u origin refactor/issue-421-instance-table
gh pr create --repo oposs/agrammon --base main --head zaucker:refactor/issue-421-instance-table --title "..." --body "..."
```
Note in the PR: stacked on #653 (task 1); the migration must run *after* the task-1 migration; `delete-instance`'s `$pattern` arg is now vestigial.
