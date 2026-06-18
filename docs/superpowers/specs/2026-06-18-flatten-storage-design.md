# Flatten storage redesign (issue #431) — design

**Issue:** oposs/agrammon #431 "Store flattened variables correctly" — *Fix storing, cleanup DB, see PR #430. Not trivial because the option keys are used in the GUI with `_` replaced with space.*

**Relationship to #421:** sibling of #421 task 3 (branch storage). *Branched* distributes one enum input's total over a 2-axis cross-product (row × col); *flattened* distributes one enum input's total over a single axis (its own options). #421 task 3 is merged (PR #657); this mirrors that work for the 1-axis case. Done **after** the branch PR.

## Problem — current flatten storage

Flattening is encoded entirely in the `data` table with no dedicated table:

- **Marker row**: `data_var = Module[]::Sub::var`, `data_val = 'flattened'`.
- **One synthetic row per option**: `data_var = Module[]::Sub::var_flattenedNN_<optionkey>`, `data_val = <percent>` (NN = zero-padded 2-digit index).

This is awkward and fragile:

- The structured map (option → percent) is encoded in identifier strings.
- The read path (`lib/Agrammon/DataSource/DB.rakumod` ~lines 58-98) is a stateful `$flattend-prefix` scan that extracts the key via a **fixed offset** `substr(($prefix ~ '_flattened00_').chars)` (breaks past 99 options; the index is otherwise vestigial), then **munges spaces to underscores** in the key (`s:g/ ' ' /_/`, lossy — the standing TODO at DB.rakumod:~91, and the exact `_`↔space nuance #431 calls out).
- The vestigial positional index is parsed **four** different ways: backend `substr` + three frontend regexes (`NavFolder.js:570`, `NavBar.js:459`, `Label.js:28`).
- No integrity: option rows are tied to their marker only by name-prefix + `ORDER BY data_var`. Rename / partial delete orphans rows.
- Per-percent writes go through the same axis-blind `store_data` path that was retired for branches.

## Goals

1. Store each flattened input as **one self-describing row** in a dedicated `flattened` table, with referential integrity to its marker `data` row.
2. Store option **keys** (canonical underscore form) — eliminating the `_`↔space munge structurally.
3. Retire the `_flattenedNN_` magic-name format from the **DB** and **both wire directions** (load and save), and from the **frontend's internal model** (identity moves to structured metadata, not parsed names).
4. Preserve backward-compat for the one external surface that can carry `_flattenedNN_`: `upload-data` dataset import.
5. No visible UX change — inline editable percent rows look and behave exactly as today.

## Non-goals / decided

- **Do NOT unify flatten + branch into one N-D `distribution` table.** PG N-D arrays are awkward: the declared type does not encode ndims (`'{1,2}'` and `'{{1},{2}}'` are both `numeric[]`); multidim arrays must be rectangular, so per-axis option lists of different lengths can't be one `text[][]`; `unnest` flattens all dimensions. Keep two typed, fixed-arity tables (`branches`, `flattened`) — symmetric and low-risk.
- **Run-input CSV/JSON are out of scope** (`DataSource::CSV`, `DataSource::JSON`): they call only `add-single-input` / `add-multi-input` and **cannot express flattening at all**; distributions are expanded (`Distribution.to-inputs`) before a run. REST `submit` feeds these. External tools' run CSVs are unaffected by this refactor.

## Data model

```sql
CREATE TABLE flattened (
    flattened_id        serial    PRIMARY KEY,
    flattened_var       integer   NOT NULL UNIQUE REFERENCES data(data_id) ON DELETE CASCADE,
    flattened_options   text[]    NOT NULL,   -- canonical enum KEYS (underscore form)
    flattened_fractions numeric[] NOT NULL,
    CHECK (cardinality(flattened_options) = cardinality(flattened_fractions))
);
```

- One row per flattened input, anchored on the marker `data` row (`data_val='flattened'`, kept as the recognition marker — frontend `value==='flattened'` checks untouched).
- `flattened_options` stores underscore-form enum keys, exactly like `branches_row_options`. No space-munge anywhere.
- `ON DELETE CASCADE` from `data(data_id)` gives integrity: deleting/renaming the instance cascades cleanly.

## Migration

`db/migrate-issue-431-flatten-storage.sql` — idempotent, mirrors the branch migration:

1. If the `flattened` table already exists, no-op.
2. For each marker var (`data_val='flattened'`), gather its `_flattenedNN_<key>` sibling rows (same dataset + instance, name prefix `<var>_flattened`), ordered by `data_var`, into `flattened_options` (the parsed keys) + `flattened_fractions` (the percents).
3. Insert one `flattened` row per marker.
4. `DELETE` the synthetic `_flattenedNN_` `data` rows.

Runs **after** the three #421 migrations: rename → instance → branch → **flatten**. The four form an ordered, idempotent chain run on each deployment.

## Backend

**Read** (`lib/Agrammon/DataSource/DB.rakumod`): delete the `$flattend-prefix` state machine, the `substr(...'_flattened00_'.chars)` offset, and the `s:g/ ' ' /_/` munge (~lines 58-98). Replace with a dedicated query mirroring the branches block immediately below it:

```sql
SELECT fv.data_var, fi.data_instance_name, f.flattened_options, f.flattened_fractions
  FROM flattened f
  JOIN data fv ON (f.flattened_var = fv.data_id)
  LEFT JOIN data_instance fi ON (fv.data_instance_id = fi.data_instance_id)
 WHERE fv.data_dataset = dataset_name2id($1,$2,$3,$4,$5)
```

Zip `options × fractions` into the percentage map → `add-multi-input-flattened` (the `Inputs` consumer is **unchanged**). The marker `data` row (`=flattened`) is skipped from the main loop just like `=branched` is.

**Store** (`lib/Agrammon/DB/Dataset.rakumod`): new `store-flattened-data(@var, $instance, @options, @fractions)`, self-contained exactly like the fixed `store-branch-data`:

1. get-or-create the instance (`!instance-id`);
2. upsert the marker var as `data_val='flattened'`, capturing `data_id` (a small helper analogous to `!branched-var-id`);
3. upsert the `flattened` row `ON CONFLICT (flattened_var)`.

**Load** (`lib/Agrammon/DB/Dataset.rakumod` `load`): attach `{options, fractions}` to each flattened marker row in the returned `data` via a `LEFT JOIN flattened`, parallel to how `branches_data` rides along today. **Ride-along** (not a separate RPC) because flattened rows display inline immediately, so no per-var round trip on load.

**upload-data** (`lib/Agrammon/DB/Dataset.rakumod`): on ingest, recognize incoming `_flattenedNN_<key>` rows, accumulate per marker var, and route to `store-flattened-data`. This is the single backward-compat boundary translation — it keeps existing exported dataset files importable. (No dataset-INPUT CSV *download* route exists; only Excel/PDF output exports.)

## Wire format + frontend

**Save:** the inline percent rows are batched into one **`store_flattened_data`** RPC `{ datasetName, data: { instance, var, options, fractions } }`, mirroring `store_branch_data`. The per-row `store_data` path for `_flattenedNN_` rows is retired. No magic names hit the backend on save.

**Load:** `__loadDatasetFunction` already special-cases `value === 'branched'` (pulls the matrix from a ride-along column). Add a parallel `value === 'flattened'` case: read the ride-along `{options, fractions}` and **build the inline percent rows locally**, the way `ConfigInstance.js:128-149` already builds them on first flatten — instead of receiving them as separate `_flattenedNN_` `data` rows.

**Remove the naming hack from the frontend's internal model.** Each inline percent row stays a table row (inline-edit UX unchanged), but its identity moves from a parsed `_flattenedNN_<key>` string to Variable metadata:

- `meta.flattenedOf = <parent var name>`, `meta.flattenedKey = <option key>`, plus order — set when the row is built.
- The row name becomes a **non-semantic** stable unique id; nothing regex-parses it.

This deletes every magic-name site:

- `NavFolder.insertData` (`:570` regex) → build rows from `{options, fractions}`: order = `parent.order + j + 1`, labels = `parent.getOptionLabels(key)`, value = `fractions[j]`, metadata as above.
- `NavBar.js:459` load-split regex → removed (load delivers structure, not magic-named rows).
- `Label.js:28` / `Replace.js` styling → key off `meta.flattenedOf` instead of the name match.
- `ConfigInstance.js:136` build → set metadata instead of composing the magic name.
- **Save**: `NavFolder.setDataset` collects the folder's flattened-option rows by `meta.flattenedOf` and emits one `store_flattened_data` per parent (the flatten analog of the branch pair-aware write).

The `_flattenedNN_` format then survives **only** as a translation shim in `upload-data` for backward-compat.

## Testing & validation

- **Backend** (`t/datasource-db.rakutest`, `t/dataset.rakutest`, `t/lib/AgrammonTest.rakumod` fixtures): flattened round-trip via the new table (store → load); the **fresh-instance** case (mirroring the branch regression added in #421 task 3); `upload-data` ingest of legacy `_flattenedNN_` rows → `flattened` table; clone. CI fixtures (`t/test-data/agrammon.schema.sql` + `agrammon_test.dump.sql`) carry the new table.
- **Suite**: full Raku suite green against a migrated scratch DB (same workflow as task 3).
- **GUI**: validate on Regional v7 (`:20003`) — flatten an input, set percentages, save, reload, copy/rename the instance.

## PR / deployment

- One PR to `oposs/agrammon`, separate from the merged branch PR (#657).
- Migrations are separate idempotent files run in order: rename → instance → branch → flatten. Downtime is per-deployment, not per-PR; the tiny/fast migrations fold into the normal stop → swap → cache-wipe → start window.

## Key files

- `db/schema.sql` + new `db/migrate-issue-431-flatten-storage.sql`
- `lib/Agrammon/DataSource/DB.rakumod` (read)
- `lib/Agrammon/DB/Dataset.rakumod` (new `store-flattened-data`, `load` ride-along, `upload-data` shim)
- `lib/Agrammon/Inputs.rakumod` (`add-multi-input-flattened` consumer — unchanged)
- `frontend/.../regional/ConfigInstance.js`, `module/input/NavFolder.js`, `NavBar.js`, `PropTable.js`, `ui/table/cellrenderer/input/Label.js`, `Replace.js`
- CI fixtures `t/test-data/agrammon.schema.sql` + `agrammon_test.dump.sql`
- Tests `t/datasource-db.rakutest`, `t/dataset.rakutest`
