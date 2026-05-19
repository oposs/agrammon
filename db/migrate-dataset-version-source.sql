-- Migration for the schema change: dataset_version is now sourced from
-- Model.version (the running deployment's internal model identifier),
-- previously from Database.version (the YAML field that was dropped).
--
-- Existing rows were written with the OLD Database.version values
-- (typically '6.0', '7.0', sometimes per-major shorthand). After the
-- change, the running deployment looks for datasets tagged with its
-- Model.version ('6.6.0', '7.0.0', '6.5.2', ...) and won't find legacy
-- rows — UPDATE / LOAD / DELETE silently fail (NULL dataset_id) until
-- the rows are promoted.
--
-- Run ONCE per deployment, mapping each historical dataset_version
-- value to the Model.version of the deployment that should own it.
-- Adjust the WHEN clauses to match your production history.
--
-- Always: take a pg_dump backup before running.
--
-- Example for the canonical Agrammon 6.x → 6.6.0 / 7.x → 7.0.0
-- deployment pattern; edit the version strings to fit your situation.

BEGIN;

UPDATE dataset SET dataset_version = CASE dataset_version
    WHEN '6.0'  THEN '6.6.0'
    WHEN '7.0'  THEN '7.0.0'
    ELSE dataset_version            -- leave anything else alone
END
WHERE dataset_version IN ('6.0', '7.0');

-- Sanity check before committing — review what's about to change.
-- COMMIT only if the row counts look right:
SELECT dataset_version, COUNT(*) AS row_count
  FROM dataset
 GROUP BY dataset_version
 ORDER BY dataset_version;

COMMIT;
