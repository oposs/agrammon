-- Issue #421: rename table `data_new` to `data` and adapt the backend.
--
-- Renames the table and all of its derived objects (sequence, constraints,
-- indexes) so a migrated database matches db/schema.sql exactly. The dependent
-- views (all_data, data_view), the branches -> data foreign key and the column
-- default referencing the sequence are all tracked by Postgres via object OIDs,
-- so they follow the renames automatically and need no recreation.
--
-- Run once per deployment, e.g.:
--   psql -U agrammon -d agrammon -f db/migrate-issue-421-rename-data-new-to-data.sql
--
-- Atomic: the whole rename succeeds or rolls back.

BEGIN;

ALTER TABLE    public.data_new            RENAME TO data;
ALTER SEQUENCE public.data_new_data_id_seq RENAME TO data_data_id_seq;

ALTER TABLE public.data RENAME CONSTRAINT data_new_pkey              TO data_pkey;
ALTER TABLE public.data RENAME CONSTRAINT data_new_data_var_key      TO data_data_var_key;
ALTER TABLE public.data RENAME CONSTRAINT data_new_data_dataset_fkey TO data_data_dataset_fkey;

ALTER INDEX public.data_new_data_dataset         RENAME TO data_data_dataset;
ALTER INDEX public.data_new_data_id_data_dataset RENAME TO data_data_id_data_dataset;

COMMIT;
