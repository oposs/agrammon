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
           -- Empty-string fractions are unset percents; store them as NULL
           -- (matches the app's "unset flatten percent round-trips as NULL"
           -- semantics) instead of failing the numeric cast on legacy rows.
           array_agg(NULLIF(o.data_val, '')::numeric ORDER BY o.data_var)
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
