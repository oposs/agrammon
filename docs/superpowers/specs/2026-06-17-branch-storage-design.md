# Branch storage redesign — issue #421 task 3

Date: 2026-06-17
Issue: oposs/agrammon#421 (task 3), context #443
Builds on: task 1 (#653, `data_new`→`data`) and task 2 (#654, `data_instance` table), both merged on `main`.

## Problem

A branched input is a 2-variable cross-product (A × B). Today it is stored as
**two `data` rows** (both `data_val='branched'`), each with its own `branches`
row:

```
branches (
    branches_id      PK,
    branches_var     int  REFERENCES data(data_id) ON DELETE CASCADE UNIQUE,
    branches_data    numeric[],   -- the FULL flattened matrix
    branches_options text[]       -- this variable's own option labels
)
```

- Row A: `branches_options` = A's labels; `branches_data` = the full flattened matrix.
- Row B: `branches_options` = B's labels; `branches_data` = the **same matrix again** (duplicated).

On read (`Agrammon::DataSource::DB.read`), the matrix shape is recovered
**implicitly** via `branches_data.rotor(B_options.elems)` — the column count is
inferred from the second variable's option-array length; the row count is never
stored. Convention: rows = A, cols = B.

### Fragilities (root cause: the matrix is implicit)

1. **Shape inferred, not stored** — `.rotor` on the B option count.
2. **Order-dependence** of the two sibling rows — exactly what #443 had to pin
   with `ORDER BY … data_id`. Any future change to the read ordering can
   silently transpose non-square matrices; square ones hide the bug.
3. **Duplication** — `branches_data` stored twice, nothing enforcing the copies
   (or `len = lenA × lenB`) agree.
4. **Positional-zip clone** — `clone` zips two independently-ordered result sets
   (`for flat @data Z @rows`); divergent ordering corrupts cloned matrices.
5. **Three ordering conventions** (`read`, `load-branch-data`, `clone`) must
   stay mutually consistent.

#443 added the deterministic `ORDER BY` tie-break — it patched the symptom
(non-square transpose) but left the implicit-matrix root cause in place.

## Decisions

These were settled during brainstorming (2026-06-17):

- **Storage model: Option B** — typed relational columns plus a native
  Postgres `numeric[][]` matrix on **one** row. Chosen over Option C (JSONB)
  because branching is definitionally 2-variable, so C's only real advantage
  (N-variable flexibility) is moot, while B keeps FK/cascade integrity,
  DB-enforced shape, and stays idiomatic with the existing `branches` table.
- **Migration: one-time SQL**, consistent with tasks 1 and 2. No read-time
  compatibility shim.
- **Branching stays 2-variable.** No generalization to N variables.
- **No frontend change.** The `store_branch_data` / `load_branch_data` external
  API shapes stay byte-identical (see Boundary contract below).

### Driver verification (gated Option B)

The Raku `DB::Pg` driver round-trips `numeric[][]` cleanly (verified
2026-06-17 against the `agrammon_test` DB on :55432):

- Writing a Raku array-of-arrays via a bind param (`$1`) inserts correctly.
- Reading back yields a nested `Array` of `Array`, indexable as `$m[1][2]`,
  shape preserved.
- Values come back as `Num` (e.g. `20e0`) — identical to the current
  single-dimension `branches_data numeric[]`, so no behavioural regression.

### Boundary contract (why no frontend change is needed)

The Qooxdoo `BranchEditor` already fixes the axis↔variable binding:

- **store** sends `{ instance, vars:[A,B], options:{A:[…], B:[…]}, data:[[…],[…]] }`
  where `vars[0]` is the **row** variable, `vars[1]` the **column** variable,
  and `data` is a **2-D row-major** matrix.
- **load** expects back `{ fractions:<flat row-major array>, options:[A,B] }`.

So the row/column identity comes from the frontend payload order, **not** from
`data_id` ordering. Storage keeps the 2-D matrix natively; `load-branch-data`
flattens it row-major on the way out to preserve the `fractions` shape. The
external API is unchanged.

## Design

### Schema (`db/schema.sql`)

Replace the `branches` table with a one-row-per-branch shape:

```sql
CREATE TABLE branches (
    branches_id          serial PRIMARY KEY,
    branches_row_var     integer NOT NULL REFERENCES data(data_id) ON DELETE CASCADE,
    branches_col_var     integer NOT NULL REFERENCES data(data_id) ON DELETE CASCADE,
    branches_row_options text[]    NOT NULL,
    branches_col_options text[]    NOT NULL,
    branches_matrix      numeric[] NOT NULL,          -- 2-D (numeric[][])
    UNIQUE (branches_row_var),
    UNIQUE (branches_col_var),
    CHECK (array_ndims(branches_matrix) = 2),
    CHECK (array_length(branches_matrix, 1) = cardinality(branches_row_options)),
    CHECK (array_length(branches_matrix, 2) = cardinality(branches_col_options))
);
```

- One row per branch (was two). Matrix stored **once**.
- Axis↔variable and axis↔options bindings are **explicit columns**, not an
  ordering convention.
- Shape is **DB-enforced**: 2-D, and each dimension must match its option count.
- The two `data` rows (the two branched input variables) are unchanged — they
  remain distinct model inputs; only the matrix storage is consolidated. Both
  FKs cascade, so deleting either variable removes the branch.
- Keep the existing GRANTs / ownership / sequence boilerplate equivalent to the
  current table.

### One-time migration (`db/migrate-issue-421-branch-storage.sql`)

For each existing branch (a pair of old `branches` rows that share a matrix),
fold into one new-shape row:

1. Identify the row-variable and column-variable `data_id`s using the same
   deterministic order the live read uses
   (`ORDER BY data_instance_name, data_id`): first = row (A), second = col (B).
2. `branches_row_options` / `branches_col_options` from each sibling's
   `branches_options`.
3. `branches_matrix` = reshape the flat `branches_data` into 2-D using the
   column count (var-B option count) — the same `.rotor` logic, performed once
   in SQL.
4. Collapse the two old sibling rows into one new-shape row per branch
   (keep/repurpose one, delete the redundant sibling), then drop the old
   `branches_var` / `branches_data` / `branches_options` columns and add the
   new columns/constraints. Equivalent to: build the new rows into a temp/new
   table from the old pairs, swap it in.

Idempotency / safety: write it so re-running on an already-migrated DB is a
no-op (guard on column existence). The local podman `agrammon_test` (:55432) is
the verification target.

**Deployment note:** on each deployment run the three task-#421 migrations IN
ORDER: rename (`…rename-data-new-to-data.sql`) → instance
(`…data-instance-table.sql`) → branch storage (`…branch-storage.sql`).

### Read path (`lib/Agrammon/DataSource/DB.rakumod`)

Remove the consecutive-`'branched'`-row state machine (the
`$current-branched` pairing, the `.rotor`, the "missing second step" deaths).
Read branches with a **dedicated query** that joins `branches` to `data` twice
(once on `branches_row_var`, once on `branches_col_var`) to recover both
variable names and the instance, and build each `Branched` directly from one
row. The non-branched data read stays as-is (it should now skip
`data_val='branched'` rows, which carry no value of their own).

### Write / edit / clone (`lib/Agrammon/DB/Dataset.rakumod`)

- **`store-branch-data(@vars, $instance, %options, @fractions)`** — resolve the
  two `data_id`s for `@vars[0]` (row) and `@vars[1]` (col), then INSERT … ON
  CONFLICT a **single** branch row: `row_var`, `col_var`,
  `row_options = %options{vars[0]}`, `col_options = %options{vars[1]}`,
  `matrix = @fractions` (2-D, stored natively — no flatten). The
  `ON CONFLICT (branches_row_var)` upsert refreshes options + matrix.
- **`load-branch-data(@var-names, $instance)`** — read the one branch row;
  return `{ fractions => <matrix flattened row-major>,
  options => [row_options, col_options] }` to preserve the frontend shape.
- **`clone`** — replace the `for flat @data Z @rows` positional zip with a
  single-row copy that remaps `row_var`/`col_var` to the cloned dataset's
  `data_id`s by (instance name, var name). No ordering reliance.
- **`!store-instance-variable`** — its inline branch INSERT (the `@branches` /
  `@options` path) updated to the new single-row shape, or routed through the
  same helper as `store-branch-data`.

### Fixtures and tests

- Carry the schema change into the load-bearing CI fixtures:
  `t/test-data/agrammon.schema.sql` (GitHub Actions + `t/Dockerfile`) and
  `t/test-data/agrammon_test.dump.sql` (Drone). Regenerate from a scratch DB
  loaded from the committed file + the new migration, preserving each file's
  object set (schema.sql carries audit/login/standard6 objects the dump lacks).
  These are not referenced by any `.rakutest`, so a code-only grep misses them.
- `t/inputs-branching.rakutest` stays green (it exercises the in-memory
  `Distribution`, unaffected by storage).
- Add DB round-trip coverage: store → load → read for **square and non-square**
  matrices, plus clone, asserting the matrix (and its orientation) survives.
  Run with `AGRAMMON_CFG=t/test-data/agrammon.cfg.yaml prove6 -Ilib -It/lib t/`
  against the migrated `agrammon_test`.

## Out of scope

- Frontend (Qooxdoo) changes — the API contract is preserved.
- N-variable branching — remains 2-variable.
- Touching the `data` / `data_instance` tables from tasks 1 and 2.

## Key references

- `db/schema.sql` — `branches` table.
- `lib/Agrammon/DataSource/DB.rakumod` — `read` (matrix rebuild via `.rotor`).
- `lib/Agrammon/DB/Dataset.rakumod` — `store-branch-data`, `load-branch-data`,
  `clone`, `!store-instance-variable`.
- `lib/Agrammon/Inputs.rakumod` — `Branched` class / `add-multi-input-branched`
  (matrix validation/consumption; unchanged — consumes the same `@matrix`).
- `frontend/source/class/agrammon/module/input/regional/BranchEditor.js` —
  the `store_branch_data` / `load_branch_data` payload shapes.
- #443 — the deterministic-ordering patch this redesign supersedes.
