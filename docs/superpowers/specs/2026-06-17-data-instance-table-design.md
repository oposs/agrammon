# Normalize input-instance into a `data_instance` table (#421, task 2)

## Context

Issue oposs/agrammon#421 ("Refactor DB model") task 2: *"Consider moving the
input instance name to a separate table and reference it in `data_instance`
(adapt view `data_view` for joining the tables)."*

Builds on task 1 (PR #653), which renamed the input-data table `data_new` → `data`.

### Current model (after task 1)

```
data(data_id PK, data_dataset → dataset, data_var, data_val,
     data_instance text, data_instance_order int, data_comment,
     UNIQUE(data_var, data_instance, data_dataset))
```

`data_instance` (the instance *name*, e.g. `"Cow group A"`) and
`data_instance_order` (display order) are both per-(dataset, instance)
properties, yet they are physically stored on **every data row** of that
instance. Consequences:

- Renaming an instance is a bulk `UPDATE` over all its rows.
- Reordering is a bulk `UPDATE` over all rows of each instance.
- `data_instance_order` can theoretically drift between rows of one instance
  (a latent correctness smell).

## Goal

Normalize both per-instance properties (name **and** order) into a dedicated
`data_instance` table, referenced by `data` through a foreign key. Keep all
user-facing behavior identical; reduce per-instance operations to single-row
updates; remove the order-drift risk.

## Non-goals

- Task 3 (branch-config storage optimization) — separate follow-up.
- Any change to the Qooxdoo frontend or REST contract.
- Touching the historical `share/Models/*/input_variables_*.sql` scripts.

## Design

### 1. Schema

```sql
CREATE TABLE public.data_instance (
    data_instance_id      integer PRIMARY KEY,            -- serial / owned sequence
    data_instance_dataset integer NOT NULL
        REFERENCES public.dataset(dataset_id) ON DELETE CASCADE,
    data_instance_name    text    NOT NULL,
    data_instance_order   integer,
    UNIQUE (data_instance_dataset, data_instance_name)
);

-- data table
ALTER TABLE public.data
    ADD COLUMN data_instance_id integer
        REFERENCES public.data_instance(data_instance_id) ON DELETE CASCADE;
-- replace UNIQUE(data_var, data_instance, data_dataset)
--    with UNIQUE(data_var, data_instance_id, data_dataset)
-- drop columns data_instance, data_instance_order
```

- A `NULL` `data_instance_id` denotes a non-instance (single) variable — same
  NULL semantics as the current `data_instance IS NULL`.
- Instances are per-dataset; the unique key `(dataset, name)` enforces it.
- `data_instance.data_instance_dataset` cascades on dataset delete (matching the
  existing `data → dataset` cascade); `data.data_instance_id` cascades on
  instance delete (lifecycle Approach A, below).

### 2. View `data_view`

Output columns and values are preserved exactly — only the source changes from
a single table to a join:

```sql
CREATE VIEW public.data_view AS
 SELECT d.data_id,
        d.data_dataset,
        COALESCE(replace(d.data_var, '[]'::text,
                 (('['::text || i.data_instance_name) || ']'::text)),
                 d.data_var) AS data_var,
        d.data_val,
        i.data_instance_order,
        d.data_comment
   FROM public.data d
   LEFT JOIN public.data_instance i ON (d.data_instance_id = i.data_instance_id)
  ORDER BY d.data_dataset,
        COALESCE(replace(d.data_var, '[]'::text,
                 (('['::text || i.data_instance_name) || ']'::text)),
                 d.data_var);
```

`all_data` does not reference instance columns and is left untouched. Because
`data_view`'s shape is unchanged, `Dataset.load()` and the frontend need no
changes.

### 3. Instance-row lifecycle — Approach A (cascade)

- **Create:** implicit, via a get-or-create helper on first write to an
  instance (preserves today's implicit-instance behavior).
- **Delete:** `delete-instance` deletes the `data_instance` row; the
  `ON DELETE CASCADE` removes its `data` rows. The `$pattern` argument is kept
  in the method signature but becomes vestigial (the pattern is always the
  instance-root and covers all the instance's variables).
- No orphan `data_instance` rows can exist.

### 4. Backend changes

`lib/Agrammon/DB/Dataset.rakumod`:

- **New helper** `!instance-id($db, $dataset-id, $name)` — get-or-create, returns
  `data_instance_id`.
- `!store-instance-variable`, `!store-instance-variable-comment` — resolve the
  instance id, write `data_instance_id`; `… WHERE data_instance = $x` becomes
  `… WHERE data_instance_id = $id`.
- `rename-instance` — one-row `UPDATE data_instance SET data_instance_name`
  scoped by (dataset, old-name); unique violation → `InstanceAlreadyExists`.
- `order-instances` — one `UPDATE data_instance SET data_instance_order` per
  instance.
- `delete-instance` — `DELETE FROM data_instance` by (dataset, name); cascade.
- `store-branch-data`, `load-branch-data` — replace `AND data_instance = $x`
  with `AND data_instance_id = (SELECT data_instance_id FROM data_instance
  WHERE data_instance_dataset = … AND data_instance_name = $x)`.
- `clone` — two steps: (a) copy the source dataset's `data_instance` rows into
  the new dataset; (b) copy `data` rows, remapping `data_instance_id` by joining
  old→new instance on (dataset, name).

`lib/Agrammon/DataSource/DB.rakumod`:

- `read` — join `data_instance` to obtain the name; `ORDER BY
  data_instance_name` (was `data_instance`).

### 5. Migration

`db/migrate-issue-421-data-instance-table.sql`, transactional:

```sql
BEGIN;
CREATE TABLE public.data_instance (...);

-- backfill one row per (dataset, instance); GROUP BY collapses any order drift
INSERT INTO public.data_instance (data_instance_dataset, data_instance_name, data_instance_order)
     SELECT data_dataset, data_instance, MAX(data_instance_order)
       FROM public.data
      WHERE data_instance IS NOT NULL
   GROUP BY data_dataset, data_instance;

ALTER TABLE public.data ADD COLUMN data_instance_id integer
    REFERENCES public.data_instance(data_instance_id) ON DELETE CASCADE;

UPDATE public.data d
   SET data_instance_id = i.data_instance_id
  FROM public.data_instance i
 WHERE d.data_dataset   = i.data_instance_dataset
   AND d.data_instance  = i.data_instance_name;

DROP VIEW public.data_view;                       -- depends on columns being dropped
ALTER TABLE public.data DROP CONSTRAINT data_data_var_key;
ALTER TABLE public.data DROP COLUMN data_instance, DROP COLUMN data_instance_order;
ALTER TABLE public.data ADD CONSTRAINT data_data_var_key
    UNIQUE (data_var, data_instance_id, data_dataset);
CREATE VIEW public.data_view AS ...;              -- new join form
COMMIT;
```

### 6. Tests & fixtures

- Update the inline schema in `t/lib/AgrammonTest.rakumod` and
  `t/datasource-db.rakutest`.
- Regenerate `t/test-data/agrammon.schema.sql` and `agrammon_test.dump.sql` by
  `pg_dump`-ing the migrated test database (avoids hand-editing COPY data).
- Verify `datasource-db` (22) and `dataset` (16) green against the test DB.
- Add round-trip coverage for rename / reorder / delete / clone through the new
  table.

### 7. Branching

Stacked on the task-1 branch `refactor/issue-421-rename-data-table`
(this builds on the renamed `data` table); its own PR.

## Risks

- Touches the core dataset read/write/clone paths (live GUI surface) — mitigated
  by preserving `data_view` output and full DB-test coverage.
- `clone` remap is the fiddliest change — covered by an explicit round-trip test.
- The pg_dump-regenerated fixtures must be reviewed to confirm only the intended
  structural change (instance table + FK) differs.
