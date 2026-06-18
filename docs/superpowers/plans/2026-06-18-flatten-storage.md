# Flatten Storage Redesign (#431) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Store each flattened input as one self-describing row in a dedicated `flattened` table (mirroring the merged #421 `branches` table), and retire the `_flattenedNN_` magic-name format from the DB, both wire directions, and the frontend's internal model — keeping it only as an `upload-data` backward-compat shim.

**Architecture:** A flattened input = one enum input whose total is distributed over its own options (1 axis). Today it is stored as a `data_val='flattened'` marker row plus one synthetic `data` row per option named `<var>_flattenedNN_<key>`, parsed by a backend state machine and three frontend regexes, with a lossy space↔underscore munge. This plan adds a `flattened(flattened_var FK→data, flattened_options text[], flattened_fractions numeric[])` table, a dedicated read query, a self-contained `store-flattened-data`, a load ride-along, an `upload-data` translation shim, and a frontend that builds the inline percent rows from structured `{options, fractions}` carried in `load_dataset` and saves them via one `store_flattened_data` RPC.

**Tech Stack:** Raku (backend, `DB::Pg`), PostgreSQL (manual migrations, no ORM), Qooxdoo JS (frontend), Raku `Test` (`.rakutest`).

**Spec:** `docs/superpowers/specs/2026-06-18-flatten-storage-design.md`

**Reference (already merged):** the #421 task-3 branch work is the template throughout — `branches` table in `db/schema.sql`, `store-branch-data`/`!branched-var-id`/`load-branch-data` in `lib/Agrammon/DB/Dataset.rakumod`, the branches read block in `lib/Agrammon/DataSource/DB.rakumod`, and `db/migrate-issue-421-branch-storage.sql`.

## Conventions used in every task

- **DB for backend tests:** a migrated scratch clone on the test postgres `:55432`. Create it once (see Task 0). The full suite is run with `AGRAMMON_CFG=/tmp/zaucker/agrammon.cfg.421.yaml` pointing at it.
- **Single-file test run:** `AGRAMMON_CFG=/tmp/zaucker/agrammon.cfg.421.yaml raku -Ilib -It/lib t/dataset.rakutest`
- **Frontend has no unit-test harness** — frontend tasks end in a GUI-validation step on Regional v7 (`:20003`) + a commit, not an automated test.
- **Commit after every task.** Branch: `refactor/issue-431-flatten-storage` (already created off `main`).

---

## Task 0: Scratch test DB with the (future) flattened schema

**Files:** none (environment setup)

- [ ] **Step 1: Recreate the scratch DB from the test template**

The test DB `agrammon_test` on `:55432` is on the pre-flatten schema; AgrammonTest builds its own tables but the persistent DB may hold stale ones. Recreate a clean scratch clone:

```bash
PGPASSWORD=postgres psql -h localhost -p 55432 -U postgres -c \
  "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='agrammon_test' AND pid<>pg_backend_pid();"
PGPASSWORD=postgres psql -h localhost -p 55432 -U postgres -c "DROP DATABASE IF EXISTS agrammon_test_431;"
PGPASSWORD=postgres psql -h localhost -p 55432 -U postgres -c "CREATE DATABASE agrammon_test_431 TEMPLATE agrammon_test OWNER agrammon;"
sed 's/name:     agrammon_test/name:     agrammon_test_431/' t/test-data/agrammon.cfg.yaml > /tmp/zaucker/agrammon.cfg.431.yaml
```

- [ ] **Step 2: Apply the #421 branch migration to the scratch DB (prerequisite schema)**

```bash
PGPASSWORD=agrammon psql -v ON_ERROR_STOP=1 -h localhost -p 55432 -U agrammon -d agrammon_test_431 \
  -f db/migrate-issue-421-branch-storage.sql
```

Expected: `BEGIN / DO / COMMIT` (or a "already migrated" notice if the template was already migrated). The flatten migration (Task 2) will be applied to this same DB.

> Note: from here on, single-file test runs and the full suite use `AGRAMMON_CFG=/tmp/zaucker/agrammon.cfg.431.yaml`.

---

## Task 1: `flattened` table in the canonical + CI schemas

**Files:**
- Modify: `db/schema.sql`
- Modify: `t/lib/AgrammonTest.rakumod` (test-time `CREATE TABLE`)
- Modify: `t/test-data/agrammon.schema.sql` (GitHub CI init)
- Modify: `t/test-data/agrammon_test.dump.sql` (Drone CI init)

- [ ] **Step 1: Add the table to the canonical schema**

In `db/schema.sql`, after the `branches` table/sequence/constraints/FK/ACL blocks, add the mirror objects for `flattened`. Insert the table near the `branches` CREATE TABLE (around line 188):

```sql
--
-- Name: flattened; Type: TABLE; Schema: public; Owner: agrammon
--

CREATE TABLE public.flattened (
    flattened_id integer NOT NULL,
    flattened_var integer NOT NULL,
    flattened_options text[] NOT NULL,
    flattened_fractions numeric[] NOT NULL,
    CONSTRAINT flattened_card CHECK ((cardinality(flattened_options) = cardinality(flattened_fractions)))
);


ALTER TABLE public.flattened OWNER TO agrammon;

--
-- Name: flattened_flattened_id_seq; Type: SEQUENCE; Schema: public; Owner: agrammon
--

CREATE SEQUENCE public.flattened_flattened_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.flattened_flattened_id_seq OWNER TO agrammon;

--
-- Name: flattened_flattened_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: agrammon
--

ALTER SEQUENCE public.flattened_flattened_id_seq OWNED BY public.flattened.flattened_id;
```

Add the DEFAULT (near the `branches branches_id` DEFAULT, ~line 468):

```sql
ALTER TABLE ONLY public.flattened ALTER COLUMN flattened_id SET DEFAULT nextval('public.flattened_flattened_id_seq'::regclass);
```

Add the PK + UNIQUE (near the branches constraints, ~line 548):

```sql
ALTER TABLE ONLY public.flattened
    ADD CONSTRAINT flattened_pkey PRIMARY KEY (flattened_id);

ALTER TABLE ONLY public.flattened
    ADD CONSTRAINT flattened_var_key UNIQUE (flattened_var);
```

Add the FK (near the branches FKs, ~line 688):

```sql
ALTER TABLE ONLY public.flattened
    ADD CONSTRAINT flattened_var_fkey FOREIGN KEY (flattened_var) REFERENCES public.data(data_id) ON DELETE CASCADE;
```

Add the ACLs (near the branches ACL, ~line 798):

```sql
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.flattened TO agrammon_user;
GRANT SELECT,UPDATE ON SEQUENCE public.flattened_flattened_id_seq TO agrammon_user;
```

- [ ] **Step 2: Add the table to the test-time schema builder**

In `t/lib/AgrammonTest.rakumod`, right after the `CREATE TABLE IF NOT EXISTS branches (...)` block (ends ~line 90), add:

```raku
    $db.query(q:to/SQL/);
    CREATE TABLE IF NOT EXISTS flattened (
        flattened_id        SERIAL    NOT NULL PRIMARY KEY,
        flattened_var       INTEGER   NOT NULL UNIQUE REFERENCES data(data_id) ON DELETE CASCADE,
        flattened_options   TEXT[]    NOT NULL,
        flattened_fractions NUMERIC[] NOT NULL,
        CHECK (cardinality(flattened_options) = cardinality(flattened_fractions))
    )
    SQL
```

- [ ] **Step 3: Mirror the table into both CI fixtures**

Apply the same DDL blocks from Step 1 to `t/test-data/agrammon.schema.sql` and `t/test-data/agrammon_test.dump.sql` (both are `pg_dump`-style; add the table, sequence, default, pkey, unique, fk, and ACL objects next to the existing `branches` ones). Keep each file's existing object ordering style.

- [ ] **Step 4: Verify the canonical schema is loadable**

```bash
PGPASSWORD=postgres psql -h localhost -p 55432 -U postgres -c "DROP DATABASE IF EXISTS agrammon_schema_check;"
PGPASSWORD=postgres psql -h localhost -p 55432 -U postgres -c "CREATE DATABASE agrammon_schema_check OWNER agrammon;"
PGPASSWORD=agrammon psql -v ON_ERROR_STOP=1 -h localhost -p 55432 -U agrammon -d agrammon_schema_check -f t/test-data/agrammon.schema.sql >/dev/null && echo "schema.sql loads OK"
PGPASSWORD=postgres psql -h localhost -p 55432 -U postgres -c "DROP DATABASE agrammon_schema_check;"
```

Expected: `schema.sql loads OK`.

- [ ] **Step 5: Commit**

```bash
git add db/schema.sql t/lib/AgrammonTest.rakumod t/test-data/agrammon.schema.sql t/test-data/agrammon_test.dump.sql
git commit -m "db(#431): flattened table schema + CI fixtures"
```

---

## Task 2: Migration — fold `_flattenedNN_` rows into `flattened`

**Files:**
- Create: `db/migrate-issue-431-flatten-storage.sql`

- [ ] **Step 1: Write the migration**

Create `db/migrate-issue-431-flatten-storage.sql`. It creates the table (if missing), folds each marker var's synthetic option rows into one `flattened` row (option key recovered by stripping the `<var>_flattenedNN_` prefix and converting spaces back to underscores — the inverse of the old read munge), then deletes the synthetic rows. Idempotent: a second run finds nothing to fold.

```sql
-- Issue #431: store flattened inputs in a dedicated self-describing table,
-- mirroring the #421 branches table. Idempotent. Run AFTER the three #421
-- migrations (rename -> instance -> branch).
BEGIN;

CREATE TABLE IF NOT EXISTS flattened (
    flattened_id        serial    PRIMARY KEY,
    flattened_var       integer   NOT NULL UNIQUE REFERENCES data(data_id) ON DELETE CASCADE,
    flattened_options   text[]    NOT NULL,
    flattened_fractions numeric[] NOT NULL,
    CONSTRAINT flattened_card CHECK (cardinality(flattened_options) = cardinality(flattened_fractions))
);

DO $migrate$
BEGIN
    -- Fold each marker var's _flattenedNN_<key> siblings into one flattened row.
    -- Order by data_var so the zero-padded NN index gives the option order.
    -- Key recovery: drop the "<marker>_flattenedNN_" prefix (NN = 2 digits, so
    -- the prefix length is char_length(marker) + length('_flattened') + 2 + 1),
    -- then space -> underscore (inverse of the retired read-time munge).
    INSERT INTO flattened (flattened_var, flattened_options, flattened_fractions)
    SELECT m.data_id,
           array_agg(replace(substr(o.data_var, char_length(m.data_var) + 14), ' ', '_')
                     ORDER BY o.data_var),
           array_agg(o.data_val::numeric ORDER BY o.data_var)
      FROM data m
      JOIN data o
        ON o.data_dataset = m.data_dataset
       AND o.data_instance_id IS NOT DISTINCT FROM m.data_instance_id
       AND o.data_var LIKE m.data_var || '\_flattened%'
     WHERE m.data_val = 'flattened'
       AND NOT EXISTS (SELECT 1 FROM flattened f WHERE f.flattened_var = m.data_id)
     GROUP BY m.data_id;

    -- Drop the now-redundant synthetic option rows.
    DELETE FROM data o
     USING data m
     WHERE m.data_val = 'flattened'
       AND o.data_dataset = m.data_dataset
       AND o.data_instance_id IS NOT DISTINCT FROM m.data_instance_id
       AND o.data_var LIKE m.data_var || '\_flattened%';
END $migrate$;

COMMIT;
```

- [ ] **Step 2: Apply it to the scratch DB and verify idempotency**

```bash
PGPASSWORD=agrammon psql -v ON_ERROR_STOP=1 -h localhost -p 55432 -U agrammon -d agrammon_test_431 -f db/migrate-issue-431-flatten-storage.sql
# second run must also succeed (no-op)
PGPASSWORD=agrammon psql -v ON_ERROR_STOP=1 -h localhost -p 55432 -U agrammon -d agrammon_test_431 -f db/migrate-issue-431-flatten-storage.sql
PGPASSWORD=agrammon psql -h localhost -p 55432 -U agrammon -d agrammon_test_431 -tA -c \
  "SELECT 'flattened table cols: '||string_agg(column_name, ',') FROM information_schema.columns WHERE table_name='flattened';"
```

Expected: both runs `BEGIN/DO/COMMIT`; cols = `flattened_id,flattened_var,flattened_options,flattened_fractions`.

- [ ] **Step 3: Commit**

```bash
git add db/migrate-issue-431-flatten-storage.sql
git commit -m "db(#431): migration folding _flattenedNN_ rows into flattened table"
```

---

## Task 3: Test fixture — a seeded flattened input

**Files:**
- Modify: `t/lib/AgrammonTest.rakumod`

Seed one flattened input on the existing `BranchTest` dataset (dataset id `-42000`, instance `Branched`, id `-91000`) so read/load tests have data. Mirrors the branches fixture rows.

- [ ] **Step 1: Add the marker data row + flattened row to the fixture**

In `t/lib/AgrammonTest.rakumod`, after the `INSERT INTO branches (...)` fixture block (~line 124), add:

```raku
    # Flattened input fixture (issue #431): one marker data row + one self-
    # describing flattened row. housing_system distributed over 3 options.
    $db.query(q:to/SQL/);
    INSERT INTO data (data_id, data_dataset, data_var, data_instance_id, data_val)
                 VALUES (-76315990, -42000, 'Livestock::Poultry[]::Housing::Type::housing_system', -91000, 'flattened')
    SQL

    $db.query(q:to/SQL/);
    INSERT INTO flattened (flattened_id, flattened_var, flattened_options, flattened_fractions)
         VALUES (-31000, -76315990,
                 '{deep_litter,aviary,floor_housing}',
                 '{50,30,20}')
    SQL
```

- [ ] **Step 2: Verify the fixture loads (run an existing test that builds the schema)**

```bash
AGRAMMON_CFG=/tmp/zaucker/agrammon.cfg.431.yaml raku -Ilib -It/lib t/dataset.rakutest 2>&1 | tail -3
```

Expected: suite still green (22 subtests) — the new fixture rows just need to insert without error.

- [ ] **Step 3: Commit**

```bash
git add t/lib/AgrammonTest.rakumod
git commit -m "test(#431): seed a flattened input in the BranchTest fixture"
```

---

## Task 4: Backend — `store-flattened-data` + RPC wiring

**Files:**
- Modify: `lib/Agrammon/DB/Dataset.rakumod` (new `!flattened-var-id`, `store-flattened-data`)
- Modify: `lib/Agrammon/Web/Service.rakumod` (new `store-flattened-data` method)
- Modify: `lib/Agrammon/Web/Routes.rakumod` (new `store_flattened_data` route)
- Test: `t/dataset.rakutest`

- [ ] **Step 1: Write the failing test**

Add a subtest to `t/dataset.rakutest` after the branch subtests (after "store-branch-data creates data rows for a fresh instance"). Increment the file's top `plan` by 1.

```raku
    subtest 'store-flattened-data persists a self-describing flattened row (#431)' => {
        plan 4;
        # Fresh instance: the marker data row does not exist yet; store must
        # create it (data_val='flattened') and write the flattened row.
        my $var = 'Livestock::Poultry[]::Housing::Type::housing_system';
        $dataset = Agrammon::DB::Dataset.new(:name<BranchTest>, :$user,
            :agrammon-variant(version => '6.0', gui => 'Regional', model => 'Base')).load;
        lives-ok {
            $dataset.store-flattened-data($var, 'FreshFlat',
                ['deep litter', 'aviary', 'floor housing'], [60, 25, 15])
        }, 'store-flattened-data on a fresh instance does not die';

        my $db = $*AGRAMMON-DB-HANDLE;
        my $marker = $db.query(q:to/SQL/, $var).value;
            SELECT count(*) FROM data d
              JOIN data_instance di ON d.data_instance_id = di.data_instance_id
             WHERE di.data_instance_dataset = -42000 AND di.data_instance_name = 'FreshFlat'
               AND d.data_var = $1 AND d.data_val = 'flattened'
            SQL
        is $marker, 1, 'marker data row persisted with data_val=flattened';

        my @row = $db.query(q:to/SQL/, $var).hashes;
            SELECT f.flattened_options AS opts, f.flattened_fractions AS fracs
              FROM flattened f
              JOIN data d ON f.flattened_var = d.data_id
              JOIN data_instance di ON d.data_instance_id = di.data_instance_id
             WHERE di.data_instance_name = 'FreshFlat' AND d.data_var = $1
            SQL
        is-deeply @row[0]<opts>, [< deep_litter aviary floor_housing >],
            'option keys stored underscore-form (no space munge)';
        is-deeply @row[0]<fracs>.map(+*).Array, [60e0, 25e0, 15e0],
            'fractions stored in option order';
    }
```

- [ ] **Step 2: Run it to verify it fails**

```bash
AGRAMMON_CFG=/tmp/zaucker/agrammon.cfg.431.yaml raku -Ilib -It/lib t/dataset.rakutest 2>&1 | grep -E "store-flattened|No such method|not ok|planned"
```

Expected: FAIL — `No such method 'store-flattened-data'`.

- [ ] **Step 3: Implement `!flattened-var-id` + `store-flattened-data`**

In `lib/Agrammon/DB/Dataset.rakumod`, immediately after `store-branch-data` (after its closing `}`, ~line 848), add:

```raku
    # Ensure a flattened variable's marker data row exists for $instance-id with
    # data_val='flattened' and return its data_id (mirrors !branched-var-id).
    method !flattened-var-id($db, $instance-id, $variable) {
        my $ret = $db.query(q:to/SQL/, $instance-id, $variable);
            UPDATE data SET data_val = 'flattened'
             WHERE data_instance_id = $1 AND data_var = $2
            RETURNING data_id
        SQL
        return $ret.value if $ret.rows;

        $ret = $db.query(q:to/SQL/, $instance-id, $variable);
            INSERT INTO data (data_dataset, data_var, data_val, data_instance_id)
                 VALUES ((SELECT data_instance_dataset FROM data_instance WHERE data_instance_id = $1),
                         $2, 'flattened', $1)
            RETURNING data_id
        SQL
        return $ret.value;
    }

    method store-flattened-data(Str $var, Str $instance, @options, @fractions) {
        my $dataset-name = $!name;
        self.with-db: -> $db {
            my $username    = $!user.username;
            my $instance-id = self!instance-id($db, $username, $instance);

            my $var-id     = self!flattened-var-id($db, $instance-id, $var);
            my @opt-keys   = @options.map(*.subst(' ', '_', :g));
            my @fracs      = @fractions.map(+*).Array;

            my $ret = $db.query(q:to/SQL/, $var-id, @opt-keys, @fracs);
                INSERT INTO flattened (flattened_var, flattened_options, flattened_fractions)
                              VALUES ($1, $2, $3)
                ON CONFLICT (flattened_var)
                DO
                    UPDATE SET flattened_options   = EXCLUDED.flattened_options,
                               flattened_fractions = EXCLUDED.flattened_fractions
                SQL
            die X::Agrammon::DB::Dataset::StoreFlattenedDataFailed.new(:variable($var)) unless $ret;

            $db.query(q:to/SQL/, $username, $dataset-name, |self!variant);
                    UPDATE dataset SET dataset_mod_date = CURRENT_TIMESTAMP
                     WHERE dataset_id=dataset_name2id($1,$2,$3,$4,$5)
                SQL
        }
    }
```

- [ ] **Step 4: Add the exception class**

Find where `X::Agrammon::DB::Dataset::StoreBranchDataFailed` is declared (grep below) and add a parallel `StoreFlattenedDataFailed` next to it.

```bash
grep -rn "StoreBranchDataFailed" lib/Agrammon/
```

At that declaration site add:

```raku
class X::Agrammon::DB::Dataset::StoreFlattenedDataFailed is Exception {
    has $.variable;
    method message() { "Could not store flattened data for variable $!variable" }
}
```

(Match the exact shape of the `StoreBranchDataFailed` class found above — same base class, same attribute/method style.)

- [ ] **Step 5: Run the test to verify it passes**

```bash
AGRAMMON_CFG=/tmp/zaucker/agrammon.cfg.431.yaml raku -Ilib -It/lib t/dataset.rakutest 2>&1 | grep -E "store-flattened|not ok|^ok|planned" | tail -8
```

Expected: the new subtest passes; whole file green.

- [ ] **Step 6: Wire the RPC — Service method**

In `lib/Agrammon/Web/Service.rakumod`, after `store-branch-data` (~line 601), add:

```raku
    method store-flattened-data(Agrammon::Web::SessionUser $user, Str $name, %data) {
        Agrammon::DB::Dataset.new(
            :$user,
            :agrammon-variant($!cfg.agrammon-variant),
            :$name
        ).lookup.store-flattened-data(%data<var>, %data<instance>, %data<options>, %data<fractions>);
        $!outputs-cache.invalidate($user.username, $name);
    }
```

- [ ] **Step 7: Wire the RPC — Route**

In `lib/Agrammon/Web/Routes.rakumod`, after the `store_branch_data` route (~line 596), add:

```raku
        post -> LoggedIn $user, 'store_flattened_data' {
            request-body -> (:datasetName($dataset-name)!, :%data!) {
                $ws.store-flattened-data($user, $dataset-name, %data);
                CATCH {
                    .note;
                    when X::Agrammon::DB::Dataset::StoreFlattenedDataFailed {
                        conflict 'application/json', %( error => .message );
                    }
                }
            }
        }
```

- [ ] **Step 8: Compile-check + rerun test**

```bash
raku -Ilib -c lib/Agrammon/Web/Routes.rakumod && raku -Ilib -c lib/Agrammon/Web/Service.rakumod && echo "Syntax OK"
AGRAMMON_CFG=/tmp/zaucker/agrammon.cfg.431.yaml raku -Ilib -It/lib t/dataset.rakutest 2>&1 | tail -2
```

Expected: `Syntax OK`; file green.

- [ ] **Step 9: Commit**

```bash
git add lib/Agrammon/DB/Dataset.rakumod lib/Agrammon/Web/Service.rakumod lib/Agrammon/Web/Routes.rakumod t/dataset.rakutest
git commit -m "db(#431): self-contained store-flattened-data + store_flattened_data RPC"
```

---

## Task 5: Backend — dedicated read query (retire the state machine)

**Files:**
- Modify: `lib/Agrammon/DataSource/DB.rakumod`
- Test: `t/datasource-db.rakutest`

- [ ] **Step 1: Write the failing test**

Add to `t/datasource-db.rakutest` a check that the seeded flattened input (Task 3 fixture) round-trips through `read` into a flattened distribution with underscore-form keys. First inspect the file's existing structure/plan and helper for building inputs:

```bash
grep -n "plan\|subtest\|read\|Flattened\|flattened\|add-multi-input" t/datasource-db.rakutest | head -30
```

Add a subtest (increment the file plan accordingly) asserting the `Branched`-instance dataset read yields a `Flattened` distribution for `housing_system` whose `value-percentages` is `{deep_litter => 50, aviary => 30, floor_housing => 20}`. Use the same dataset-read entry point the existing tests use (mirror an existing `read` assertion in that file).

```raku
    subtest 'flattened input reads from the dedicated table (#431)' => {
        plan 2;
        my $inputs = read-dataset();   # <- use the file's existing read helper/call
        my @flat = $inputs.distributed-inputs-for('Livestock::Poultry', 'Branched')
                          .grep(* ~~ Agrammon::Inputs::Flattened);
        is @flat.elems, 1, 'one flattened input recovered';
        is-deeply @flat[0].value-percentages,
            { deep_litter => 50, aviary => 30, floor_housing => 20 },
            'underscore-form keys + fractions, no state machine / munge';
    }
```

> Adapt `read-dataset()` and `distributed-inputs-for(...)` to the actual helpers/accessors used elsewhere in `t/datasource-db.rakutest` and `Agrammon::Inputs` (grep in Step 1). The asserted *values* are the contract.

- [ ] **Step 2: Run it to verify it fails**

```bash
AGRAMMON_CFG=/tmp/zaucker/agrammon.cfg.431.yaml raku -Ilib -It/lib t/datasource-db.rakutest 2>&1 | grep -E "flattened input reads|not ok|planned" | head
```

Expected: FAIL — the old state-machine read still works off `_flattenedNN_` rows, which no longer exist for the fixture (the fixture now seeds the `flattened` table), so the distribution is empty/absent.

- [ ] **Step 3: Replace the read state machine with a dedicated query**

In `lib/Agrammon/DataSource/DB.rakumod`, delete the flattened state-machine branch (the `state $flattend-prefix` / `state Flattened $current-flattened` declarations at ~58-59, the `if $value and $value eq 'flattened' {...}` and `elsif $flattend-prefix && ... {...}` arms at ~80-94, and the trailing `@flattend-to-add` loop at ~112-115). The marker row must now be skipped like `branched`:

Change the early skip (currently line 63) to also skip the flattened marker:

```raku
                # branched/flattened marker rows carry no value of their own;
                # their distribution is rebuilt from the dedicated queries below.
                next if $value && ($value eq 'branched' || $value eq 'flattened');
```

After the branches block (after its `for @branches -> @b {...}` loop, ~line 137), add the flattened block:

```raku
            # Flattened inputs: one self-describing row each, joined to the marker
            # data row to recover variable name + instance. Options/fractions zip
            # directly into the percentage map (no state machine / substr / munge).
            my @flattened = $db.query(q:to/STATEMENT/, $user, $dataset, %variant<version>, %variant<gui>, %variant<model>).arrays;
                SELECT fv.data_var, fi.data_instance_name,
                       f.flattened_options, f.flattened_fractions
                FROM flattened f
                JOIN data fv ON (f.flattened_var = fv.data_id)
                LEFT JOIN data_instance fi ON (fv.data_instance_id = fi.data_instance_id)
                WHERE fv.data_dataset = dataset_name2id($1,$2,$3,$4,$5)
            STATEMENT

            for @flattened -> @f {
                my ($tax, $sub, $var) = parse-branch-var(@f[0]);
                my %value-percentages = @f[2].list Z=> @f[3].list;
                $dist-input.add-multi-input-flattened($tax, @f[1], $sub, $var, %value-percentages);
            }
```

> `parse-branch-var` is the existing helper used by the branches block to split `Tax[]::Sub::var` into `($tax, $sub, $var)`. Reuse it. `@f[3]` (numeric[]) values are `Real`; `add-multi-input-flattened` sums them — no coercion needed, but if the dupe/sum guard is strict, map `+*` over the fractions.

- [ ] **Step 4: Run the read test (and the full DB read test file)**

```bash
AGRAMMON_CFG=/tmp/zaucker/agrammon.cfg.431.yaml raku -Ilib -It/lib t/datasource-db.rakutest 2>&1 | tail -4
```

Expected: green, including the new subtest.

- [ ] **Step 5: Commit**

```bash
git add lib/Agrammon/DataSource/DB.rakumod t/datasource-db.rakutest
git commit -m "db(#431): read flattened inputs from the dedicated table (retire state machine)"
```

---

## Task 6: Backend — load ride-along (`Dataset.load`)

**Files:**
- Modify: `lib/Agrammon/DB/Dataset.rakumod` (`load`)
- Test: `t/dataset.rakutest`

- [ ] **Step 1: Write the failing test**

Add a subtest to `t/dataset.rakutest` (increment plan) asserting `load` attaches the flattened distribution to the marker row. The fixture marker is `housing_system` on instance `Branched`.

```raku
    subtest 'load attaches flattened distribution to the marker row (#431)' => {
        plan 2;
        $dataset = Agrammon::DB::Dataset.new(:name<BranchTest>, :$user,
            :agrammon-variant(version => '6.0', gui => 'Regional', model => 'Base')).load;
        my @marker = $dataset.data.grep({
            .[0].contains('housing_system') && .[1] eq 'flattened'
        });
        is @marker.elems, 1, 'one flattened marker row present';
        # column index 5 = the ride-along {options, fractions} (see load query)
        is-deeply @marker[0][5],
            { options => [< deep_litter aviary floor_housing >], fractions => [50e0, 30e0, 20e0] },
            'marker row carries the flattened distribution';
    }
```

> Confirm the marker row's column order from the `load` SELECT; the ride-along is appended as the last selected column. Adjust the index `[5]` if the column count differs.

- [ ] **Step 2: Run it to verify it fails**

```bash
AGRAMMON_CFG=/tmp/zaucker/agrammon.cfg.431.yaml raku -Ilib -It/lib t/dataset.rakutest 2>&1 | grep -E "attaches flattened|not ok|planned" | head
```

Expected: FAIL — index out of range / no ride-along column.

- [ ] **Step 3: Add the ride-along to the load query**

In `lib/Agrammon/DB/Dataset.rakumod` `load` (~lines 414-424), extend the SELECT with a correlated subquery building a JSON-ish hash of `{options, fractions}` for flattened marker rows, parallel to the existing `branches_data` subquery. Replace the SELECT with:

```raku
            SELECT dv.data_var, dv.data_val, dv.data_instance_order,
                   (SELECT array_agg(x ORDER BY ord)
                      FROM unnest(b.branches_matrix) WITH ORDINALITY AS t(x, ord)) AS branches_data,
                   dv.data_comment,
                   (SELECT jsonb_build_object('options',   f.flattened_options,
                                              'fractions', f.flattened_fractions)
                      FROM flattened f WHERE f.flattened_var = dv.data_id) AS flattened_data
              FROM data_view dv
              LEFT JOIN branches b ON (b.branches_row_var = dv.data_id OR b.branches_col_var = dv.data_id)
             WHERE dv.data_dataset=dataset_name2id($1,$2,$3,$4,$5)
               AND dv.data_var not like '%::ignore'
             ORDER BY dv.data_instance_order ASC, dv.data_var
```

> The new column is appended last (index 5). `DB::Pg` returns `jsonb` decoded into a Raku hash; `flattened_options`/`flattened_fractions` decode to arrays. Non-flattened rows get a `Nil`/undefined in that slot. If the assertion in Step 1 sees numeric strings instead of `Num`, coerce in the test (`.map(+*)`) or build the object with `to_jsonb` over numeric arrays — keep the asserted values as the contract and adjust types to match `DB::Pg`'s jsonb decoding.

- [ ] **Step 4: Run the test**

```bash
AGRAMMON_CFG=/tmp/zaucker/agrammon.cfg.431.yaml raku -Ilib -It/lib t/dataset.rakutest 2>&1 | grep -E "attaches flattened|not ok|^ok|planned" | tail -6
```

Expected: green.

- [ ] **Step 5: Commit**

```bash
git add lib/Agrammon/DB/Dataset.rakumod t/dataset.rakutest
git commit -m "db(#431): ride-along flattened distribution in Dataset.load"
```

---

## Task 7: Backend — `upload-data` backward-compat shim

**Files:**
- Modify: `lib/Agrammon/DB/Dataset.rakumod` (`upload-data`)
- Test: `t/dataset.rakutest`

- [ ] **Step 1: Write the failing test**

Add a subtest (increment plan): uploading legacy `_flattenedNN_` CSV lines creates a `flattened` row, not synthetic data rows.

```raku
    subtest 'upload-data translates legacy _flattenedNN_ rows into the flattened table (#431)' => {
        plan 3;
        $dataset = Agrammon::DB::Dataset.new(:name<BranchTest>, :$user,
            :agrammon-variant(version => '6.0', gui => 'Regional', model => 'Base')).load;
        my $csv = qq:to/CSV/;
        Livestock::Poultry[Uploaded]::Housing::Type::housing_system,flattened
        Livestock::Poultry[Uploaded]::Housing::Type::housing_system_flattened00_deep litter,70
        Livestock::Poultry[Uploaded]::Housing::Type::housing_system_flattened01_aviary,30
        CSV
        lives-ok { $dataset.upload-data($csv) }, 'upload-data ingests legacy flattened rows';

        my $db = $*AGRAMMON-DB-HANDLE;
        my $synthetic = $db.query(q:to/SQL/).value;
            SELECT count(*) FROM data WHERE data_var LIKE '%\_flattened0%'
              AND data_dataset = -42000
            SQL
        is $synthetic, 0, 'no synthetic _flattenedNN_ data rows remain';

        my @row = $db.query(q:to/SQL/).hashes;
            SELECT f.flattened_options AS o, f.flattened_fractions AS fr
              FROM flattened f JOIN data d ON f.flattened_var=d.data_id
              JOIN data_instance di ON d.data_instance_id=di.data_instance_id
             WHERE di.data_instance_name='Uploaded'
            SQL
        is-deeply @row[0]<o>, [< deep_litter aviary >], 'options folded with underscore keys';
    }
```

- [ ] **Step 2: Run it to verify it fails**

```bash
AGRAMMON_CFG=/tmp/zaucker/agrammon.cfg.431.yaml raku -Ilib -It/lib t/dataset.rakutest 2>&1 | grep -E "upload-data translates|not ok|planned" | head
```

Expected: FAIL — `upload-data` still writes the synthetic rows via `store-input`, so `synthetic != 0` and no flattened row.

- [ ] **Step 3: Implement the shim in `upload-data`**

In `lib/Agrammon/DB/Dataset.rakumod` `upload-data` (~lines 430-455), buffer rows whose name matches `_flattenedNN_`, group them per marker variable+instance, and flush each group through `store-flattened-data`; pass everything else through unchanged. Replace the parse loop body:

```raku
    method upload-data($content) {
        my $fh = IO::String.new($content);
        my $csv = Text::CSV.new;
        my $i = 0;
        # Accumulate legacy `_flattenedNN_<key>` rows per (instance, marker var)
        # and fold them into one store-flattened-data call (issue #431 boundary
        # translation). Run-input CSV/JSON cannot carry flattening; only dataset
        # imports can, so this is the sole compat surface.
        my %flat;   # "$instance\0$base" => { var => …, instance => …, options => […], fractions => […] }
        sub flush-flat() {
            for %flat.values -> %g {
                self.store-flattened-data(%g<var>, %g<instance>, %g<options>, %g<fractions>);
                $i++;
            }
            %flat = ();
        }
        while (my @row = $csv.getline($fh)) {
            my ($var-name, $value) = @row;
            next unless $var-name;
            next if $var-name ~~ /^\#/;

            if $var-name ~~ /^ (.+?) '[' (.+?) ']' (.*?) '_flattened' \d ** 1..2 '_' (.+) $/ {
                my $base     = "$0\[]$2";            # marker var, instance-free
                my $instance = ~$1;
                my $key      = (~$3).subst(' ', '_', :g);
                my $slot     = %flat{"$instance\0$base"} //= {
                    :var($base), :$instance, :options([]), :fractions([])
                };
                $slot<options>.push: $key;
                $slot<fractions>.push: $value;
                next;
            }
            # A `=flattened` marker line for a var we're folding: skip it (the
            # flattened row creation sets the marker itself).
            if $value && $value eq 'flattened' {
                next;
            }

            self.store-input($var-name, $value);
            $i++;
        }
        flush-flat();
        CATCH {
            .note;
            when CSV::Diag {
                die X::Agrammon::DB::Dataset::UploadCSVError.new(:dataset-name($!name), :msg(.message));
            }
            when X::Agrammon::DB::Dataset::StoreDataFailed {
                die X::Agrammon::DB::Dataset::UploadDatabaseFailure.new(:dataset-name($!name), :msg(.message));
            }
            default {
                die X::Agrammon::DB::Dataset::UploadUnknowFailure.new(:dataset-name($!name), :msg(.message));
            }
        }
        return $i;
    }
```

> The regex splits `Tax[instance]Rest_flattenedNN_key`. `$0`=Tax, `$1`=instance, `$2`=Rest (`::Sub::var`), `$3`=key. `$base = "$0[]$2"` rebuilds the instance-free marker var (e.g. `Livestock::Poultry[]::Housing::Type::housing_system`). Verify against the fixture name shape; adjust the regex groups if the real names differ.

- [ ] **Step 4: Run the test**

```bash
AGRAMMON_CFG=/tmp/zaucker/agrammon.cfg.431.yaml raku -Ilib -It/lib t/dataset.rakutest 2>&1 | grep -E "upload-data translates|not ok|^ok|planned" | tail -6
```

Expected: green.

- [ ] **Step 5: Commit**

```bash
git add lib/Agrammon/DB/Dataset.rakumod t/dataset.rakutest
git commit -m "db(#431): upload-data folds legacy _flattenedNN_ rows into flattened table"
```

---

## Task 8: Full backend suite gate

**Files:** none

- [ ] **Step 1: Run the whole suite against the migrated scratch DB**

```bash
AGRAMMON_CFG=/tmp/zaucker/agrammon.cfg.431.yaml prove6 -Ilib -It/lib t/ 2>&1 | tail -15
```

Expected: all files green (≈551 tests). If `datasource-db.rakutest` or `dataset.rakutest` fail, fix before proceeding — the frontend tasks depend on a correct backend.

- [ ] **Step 2: Commit (only if any fixups were needed)**

```bash
git add -A && git commit -m "test(#431): backend suite green on dedicated flattened storage"
```

---

## Task 9: Frontend — save via `store_flattened_data`

**Files:**
- Modify: `frontend/source/class/agrammon/module/input/NavFolder.js`
- Modify: `frontend/source/class/agrammon/module/input/PropTable.js` (only if a per-row flattened `store_data` path exists there)

> Frontend has no unit-test harness — validate in the GUI. Recompile with `cd frontend && npx qx compile --target=source --feedback=false` and exercise on Regional v7 (`:20003`).

- [ ] **Step 1: Add `__storeFlattenedGroup` and call it from `setDataset`**

In `NavFolder.js` `setDataset` (the loop at ~607-643, alongside the `branchedVars` handling), collect flattened-option rows. Add near `var branchedVars = [];`:

```js
            // #431: flattened percent rows are persisted as one structured
            // store_flattened_data per marker var (mirrors the branch pair-aware
            // write); collect them here instead of per-row store_data.
            var flattenedGroups = {}; // markerVarName -> { rows: [], marker: data }
```

In the loop, before the generic `else` that dispatches `store_data`, branch on flattened-option rows (identified by `meta.flattenedOf`, set in Task 11) and flattened markers (`value === 'flattened'`):

```js
                    else if (value === 'flattened') {
                        // marker row: persisted by store_flattened_data below
                        var g = flattenedGroups[name] || (flattenedGroups[name] = { rows: [], marker: data });
                        g.marker = data;
                        this.setData(name, value, comment, noCheck, null);
                    }
                    else if (meta && meta.flattenedOf) {
                        var gp = flattenedGroups[meta.flattenedOf] || (flattenedGroups[meta.flattenedOf] = { rows: [], marker: null });
                        gp.rows.push({ key: meta.flattenedKey, value: value });
                        this.setData(name, value, comment, noCheck, null);
                    }
```

After the loop (next to the `branchedVars.length === 2` check), add:

```js
            if (storeAll) {
                for (var mk in flattenedGroups) {
                    if (flattenedGroups.hasOwnProperty(mk)) {
                        this.__storeFlattenedGroup(mk, flattenedGroups[mk]);
                    }
                }
            }
```

Add the method (next to `__storeBranchPair`):

```js
        // #431: persist one flattened input via store_flattened_data. The marker
        // var name carries the instance; rows carry option key + percent.
        __storeFlattenedGroup: function(markerName, group) {
            var regex = /\[(.+)\]/;
            var m = regex.exec(markerName);
            if (!m) { return; }
            var instance = m[1];
            var varName  = markerName.replace(regex, '[]');
            var options = [], fractions = [];
            for (var i = 0; i < group.rows.length; i++) {
                options.push(group.rows[i].key);
                fractions.push(Number(group.rows[i].value) || 0);
            }
            if (options.length === 0) { return; }
            var datasetName = '' + agrammon.Info.getInstance().getDatasetName();
            agrammon.io.remote.Rpc.getInstance().callAsync(
                function() {}, 'store_flattened_data',
                { datasetName: datasetName,
                  data: { instance: instance, var: varName, options: options, fractions: fractions } });
        },
```

- [ ] **Step 2: Recompile + GUI-validate save**

```bash
cd frontend && npx qx compile --target=source --feedback=false 2>&1 | grep -iE "error|Applications are made"
```

On `:20003`: create a regional instance, flatten an input, enter percentages, Save. Verify in the DB:

```bash
PGPASSWORD=agrammon psql -h localhost -p 55433 -U agrammon -d agrammon_test -P pager=off -c \
  "SELECT di.data_instance_name, d.data_var, f.flattened_options, f.flattened_fractions
     FROM flattened f JOIN data d ON f.flattened_var=d.data_id
     JOIN data_instance di ON d.data_instance_id=di.data_instance_id ORDER BY 1,2;"
```

Expected: one row per flattened input with underscore-form option keys and the entered percentages. (The `:55433` dev DB must have the #431 migration applied first — see Task 12 Step 1.)

- [ ] **Step 3: Commit**

```bash
git add frontend/source/class/agrammon/module/input/NavFolder.js frontend/source/class/agrammon/module/input/PropTable.js
git commit -m "frontend(#431): save flattened inputs via structured store_flattened_data"
```

---

## Task 10: Frontend — build inline rows from the load ride-along

**Files:**
- Modify: `frontend/source/class/agrammon/module/input/NavBar.js` (`__loadDatasetFunction`)
- Modify: `frontend/source/class/agrammon/module/input/NavFolder.js` (row build)

- [ ] **Step 1: Handle the flattened marker on load**

In `NavBar.js` `__loadDatasetFunction` (~lines 427-475), the loop reads `data[i]`. The marker row now carries the ride-along `flattened_data` (load column index 5). Where `branch_values = data[i][3]` is set for `value=='branched'`, add a flattened branch that builds the inline rows from `{options, fractions}` instead of relying on `_flattenedNN_` rows:

```js
                if (value == 'flattened') {
                    var fdata = data[i][5];   // { options:[…], fractions:[…] } | null
                    folder = this.__navHash[folderName] ? this.__navHash[folderName]['folder'] : null;
                    var res2 = folder ? folder.setData(varName, value, comment, noCheck, null) : false;
                    if (res2 === true) { nset++; }
                    if (folder && fdata && fdata.options) {
                        folder.buildFlattenedRows(varName, fdata.options, fdata.fractions);
                    }
                    continue;
                }
```

Delete the now-dead `_flattenedNN_` load split (the `var regex = /(.+)(_flattened\d?\d?_.+)$/;` block at ~459-472) — load no longer receives synthetic rows.

- [ ] **Step 2: Add `buildFlattenedRows` to NavFolder (replaces `insertData`)**

In `NavFolder.js`, replace `insertData` (~568-594) with a structured builder. It clones the marker var per option, marks it via metadata (no magic name), and orders rows after the marker:

```js
        // #431: build the inline percent rows for a flattened input from the
        // structured {options, fractions} carried by load_dataset. Identity is
        // metadata (flattenedOf / flattenedKey), not a parsed _flattenedNN_ name.
        buildFlattenedRows: function(markerName, options, fractions) {
            var marker = null, pos = -1;
            for (var i = 0; i < this.__propData.length; i++) {
                if (this.__propData[i].getName() === markerName) { marker = this.__propData[i]; pos = i; break; }
            }
            if (!marker) { return; }
            for (var j = 0; j < options.length; j++) {
                var key   = options[j];
                var rowName = markerName + '#flat#' + key;   // non-semantic, unique
                var labels  = marker.getOptionLabels(key);
                var v = marker.clone(rowName);
                v.setType('percent');
                v.setDefaultValue(null);
                v.setValue(fractions && fractions[j] != null ? '' + fractions[j] : null);
                v.setLabels(labels);
                v.setUnits({ en: '%', de: '%', fr: '%', it: '%' });
                v.setHelpIcon(null);
                v.setHelpFunction(null);
                v.setMetaData({ type: 'percent', flattenedOf: markerName, flattenedKey: key });
                v.setOrder(marker.getOrder() + j + 1);
                this.__propData.splice(pos + 1 + j, 0, v);
            }
        },
```

- [ ] **Step 3: Recompile + GUI-validate load**

```bash
cd frontend && npx qx compile --target=source --feedback=false 2>&1 | grep -iE "error|Applications are made"
```

On `:20003`: reload the dataset saved in Task 9. Expected: the flattened input shows its inline percent rows with the saved values and correct labels.

- [ ] **Step 4: Commit**

```bash
git add frontend/source/class/agrammon/module/input/NavBar.js frontend/source/class/agrammon/module/input/NavFolder.js
git commit -m "frontend(#431): build inline flattened rows from structured load data"
```

---

## Task 11: Frontend — metadata identity in build + renderers (remove magic names)

**Files:**
- Modify: `frontend/source/class/agrammon/module/input/regional/ConfigInstance.js`
- Modify: `frontend/source/class/agrammon/ui/table/cellrenderer/input/Label.js`
- Modify: `frontend/source/class/agrammon/ui/table/cellrenderer/input/Replace.js`
- Modify: `frontend/source/class/agrammon/module/input/NavFolder.js` (`isComplete`, any residual `_flattened` regex)

- [ ] **Step 1: ConfigInstance build sets metadata, not magic names**

In `ConfigInstance.js` (the flatten build at ~119-150), replace the `_flattenedNN_` name composition (`newData[i].clone(newData[i].getName()+'_flattened'+oo+'_'+options[o])`) with the non-semantic name + metadata used by `buildFlattenedRows`:

```js
                        newVar = newData[i].clone(newData[i].getName() + '#flat#' + options[o]);
                        newVar.setMetaData({ type: 'percent',
                                             flattenedOf: newData[i].getName(),
                                             flattenedKey: options[o] });
```

(Keep the rest of the per-option setup: labels, percent type/units, value null, order.)

- [ ] **Step 2: Renderers key off metadata, not the name regex**

In `Label.js` (~line 28) replace the name match with a metadata check. The cell renderer receives row data; expose the flattened flag via the row's metadata column (column 7 holds `getMetaData()` in this table — verify with the surrounding code) and test `rowData[7] && rowData[7].flattenedOf`:

```js
            if (cellInfo.rowData[7] && cellInfo.rowData[7].flattenedOf) { // flattened option row
```

In `Replace.js`, wherever it special-cases flattened option rows by name, switch to the same `meta.flattenedOf` test. (The `case 'flattened':` marker-row handling at ~35 stays — that's the marker `value`, not the option rows.)

> Verify the metadata column index against `Variable.js` `getRecord()`/`getMetaData()` push order (grep `getMetaData` in `Variable.js`; the branch code reads `tm.getValue(7, i)` for meta in `PropTable.js`). Use the same index the existing code uses for meta.

- [ ] **Step 3: Purge residual `_flattened` name parsing**

```bash
grep -rn "_flattened" frontend/source/class/agrammon/
```

Expected after this task: matches only in comments / the `#flat#` non-semantic name. Replace any remaining functional `_flattened` regex (e.g. in `NavFolder.isComplete` flattened-sum logic, or `PropTable.js` navigation at ~505-587) with `meta.flattenedOf` checks. The completeness sum over flattened rows should iterate rows whose `meta.flattenedOf === markerName`.

- [ ] **Step 4: Recompile + GUI-validate the full flatten lifecycle**

```bash
cd frontend && npx qx compile --target=source --feedback=false 2>&1 | grep -iE "error|Applications are made"
```

On `:20003`, end-to-end: create instance → flatten an input → enter percentages → Save → reload (rows + values + labels correct, styled/indented as before) → copy the instance (percentages preserved) → rename the instance (percentages preserved after reload). Confirm no `_flattenedNN_` rows exist:

```bash
PGPASSWORD=agrammon psql -h localhost -p 55433 -U agrammon -d agrammon_test -tA -c \
  "SELECT count(*) AS legacy_rows FROM data WHERE data_var LIKE '%\_flattened0%';"
```

Expected: `0`.

- [ ] **Step 5: Commit**

```bash
git add frontend/source/class/agrammon/module/input/regional/ConfigInstance.js \
        frontend/source/class/agrammon/ui/table/cellrenderer/input/Label.js \
        frontend/source/class/agrammon/ui/table/cellrenderer/input/Replace.js \
        frontend/source/class/agrammon/module/input/NavFolder.js
git commit -m "frontend(#431): identify flattened rows by metadata, retire _flattenedNN_ names"
```

---

## Task 12: Integration — dev DB migration, GUI validation, PR

**Files:** none (process)

- [ ] **Step 1: Apply the flatten migration to the dev DB (ask first — adds a table, plus folds any existing legacy rows)**

The `:55433` dev DB already has the three #421 migrations. Back it up, then apply #431:

```bash
PGPASSWORD=agrammon pg_dump -h localhost -p 55433 -U agrammon -d agrammon_test \
  -f /scratch/zaucker/tmp/agrammon_test-devdb-55433-pre431-$(date +%Y%m%d-%H%M%S).sql
PGPASSWORD=agrammon psql -v ON_ERROR_STOP=1 -h localhost -p 55433 -U agrammon -d agrammon_test \
  -f db/migrate-issue-431-flatten-storage.sql
```

> This is a `CREATE TABLE` + a fold/`DELETE` of legacy `_flattenedNN_` rows — confirm with the user before running (per the destructive-command policy). Then restart the Regional v7 server so it loads the new backend.

- [ ] **Step 2: Full GUI validation pass on Regional v7**

Repeat the Task 11 Step 4 lifecycle against the migrated dev DB. Also load a pre-existing dataset that had legacy flattened inputs and confirm they render correctly (the migration folded them).

- [ ] **Step 3: Final full-suite gate**

```bash
AGRAMMON_CFG=/tmp/zaucker/agrammon.cfg.431.yaml prove6 -Ilib -It/lib t/ 2>&1 | tail -8
```

Expected: all green.

- [ ] **Step 4: Push + open PR**

```bash
git push -u origin refactor/issue-431-flatten-storage
gh pr create --repo oposs/agrammon --base main --head zaucker:refactor/issue-431-flatten-storage \
  --title "refactor(#431): store flattened inputs in a dedicated table" \
  --body "<summary mirroring the spec: dedicated flattened table, migration, dedicated read, store_flattened_data, load ride-along, upload-data compat shim, frontend metadata identity (no _flattenedNN_). Validated: full suite + GUI on Regional v7. Migrations run in order: rename -> instance -> branch -> flatten.>"
```

- [ ] **Step 5: Admin-merge per workflow, sync main, clean up**

```bash
gh pr merge <N> --repo oposs/agrammon --admin --merge
git checkout main && git fetch upstream && git merge --ff-only upstream/main && git push origin main
git branch -d refactor/issue-431-flatten-storage
```

---

## Self-review notes (for the implementer)

- **Spec coverage:** Task 1 (table+fixtures), Task 2 (migration), Task 5 (read), Task 4 (store), Task 6 (load ride-along), Task 7 (upload-data compat), Tasks 9-11 (wire+frontend, magic-name removal), Task 12 (validation/PR) cover every spec section. The `_`↔space resolution lives in Task 4 (`subst` to underscore on store) + Task 2 (`replace` on migrate) + Task 5 (no munge on read).
- **Index/column assumptions to verify at implementation time:** the `load` ride-along column index (Task 6/10 assume `[5]`), the metadata column index in the table model (Task 11), and the exact `_flattenedNN_` name shape for the `upload-data` regex (Task 7). Each task notes the grep to confirm before coding.
- **Type-consistency:** `store-flattened-data(var, instance, options, fractions)` is the single backend signature used by Service (Task 4), `upload-data` (Task 7), and the frontend RPC payload `{ instance, var, options, fractions }` (Task 9). `meta.flattenedOf`/`meta.flattenedKey` are set in Tasks 10/11 and read in Tasks 9/11 — same names throughout.
