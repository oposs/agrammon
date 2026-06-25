- 7.0.7, 2026-06-25, fritz.zaucker@oetiker.ch

  - Fix flattened distribution percentages entered cell-by-cell not
    reaching the simulation. Editing a single flattened-option percent
    persisted it as a stray `…#flat#<option>` data row (via store_data)
    instead of into the `flattened` table, so the GUI showed the entered
    values while the run read empty or stale fractions. This produced
    silently wrong results, or a 500 ("flattened values sums to 0
    instead of 100") when the `flattened` table was all-NULL — e.g. the
    Regional model's DairyCow housing type. Percent edits now persist
    the whole distribution via store_flattened_data
    (`PropTable.__dataChanged_func` → `NavFolder.storeFlattenedForEdit`),
    and `store_data` now refuses `#flat#` variables as a safeguard.
    Affects all variants. Frontend-plus-backend change. Datasets already
    in the split state are corrected by a one-time data repair that
    backfills the `flattened` fractions from the stray rows and removes
    them (no schema migration).


- 7.0.6, 2026-06-23, fritz.zaucker@oetiker.ch

  - Fix duplicating a multi-instance module instance losing its branch
    matrix when the model's enum options had drifted since the matrix
    was stored (e.g. a 4x5 matrix against a now-4x6 model, as in the
    Regional model's Poultry housing inputs). The copy previously
    reconstructed each matrix on the frontend, reshaped to the *current*
    option counts, and silently dropped it on a dimension mismatch.
    Branch matrices are now copied verbatim server-side
    (`Dataset.copy-instance-branches`, via a new `copy_branch_data`
    RPC), preserving the stored matrix and its option arrays regardless
    of whether the model's options have since grown or shrunk. Frontend-
    plus-backend change, no DB migration. Instances copied before this
    fix can be re-copied to recover their matrix (the source kept it).


- 7.0.5, 2026-06-23, fritz.zaucker@oetiker.ch

  - Fix duplicating a multi-instance module instance losing its
    flattened percentage distributions (e.g. the Regional model's
    housing mitigation options). `cloneDataset()` renamed each cloned
    variable to the new instance label but left the `flattenedOf`
    metadata pointer referencing the source instance, so the copied
    percent rows were persisted onto the source instead of the new
    instance — the copy reloaded with the `*** Flattened ***` marker
    reverted to a bare enum Select and the percent lines gone.
    Frontend-only change — no DB migration. Instances copied before
    this fix can be re-flattened by hand.


- 7.0.4, 2026-06-23, fritz.zaucker@oetiker.ch

  - Fix copying a dataset losing its flattened percentage distributions
    (issue #431). `Dataset.clone()` now also copies the dedicated
    `flattened` table, remapping the marker variable to the new
    dataset's data rows; previously only the `data`, `data_instance`,
    and `branches` rows were cloned. Code-only change — no DB migration;
    datasets copied before this fix cannot recover their lost
    percentages.


- 7.0.3, 2026-06-20, fritz.zaucker@oetiker.ch

  - Read branch matrices order-independently. `load-branch-data` now
    finds a branch by either axis variable and re-keys the stored matrix
    onto each variable's current model enum order (matching by canonical
    option key). This keeps branch editing stable regardless of how the
    stored row/col axes are oriented — including branches migrated from
    the old two-row layout — and across model changes such as enum
    reordering, added/removed options, and cross-version aliases. New
    options with no stored value read as 0; no stored data is modified.

  - Database storage refactor (issue #421). Requires a one-time DB
    migration (run with all instances stopped):
    - Rename the `data_new` table to `data`
      (`db/migrate-issue-421-rename-data-new-to-data.sql`).
    - Normalize per-instance name and display order into a dedicated
      `data_instance` table referenced by foreign key
      (`db/migrate-issue-421-data-instance-table.sql`).
    - Collapse the two-row-per-branch `branches` design into one
      self-describing row per branch
      (`db/migrate-issue-421-branch-storage.sql`).

  - Store flattened inputs in a dedicated self-describing `flattened`
    table, retiring the `_flattenedNN_` synthetic option rows and the
    read-time state machine (issue #431). Requires the migration
    `db/migrate-issue-431-flatten-storage.sql`, run after the three
    issue #421 migrations.

  - Technical parameter values are now single-sourced from the
    Environment config; the `.nhd` `value=` fallback is dropped
    (issue #217).

  - Unify the `default_calc` and `default_gui` formula attributes into a
    single `default_value` (issue #555).

  - Run REST API batch simulations in parallel with a bounded degree,
    and apply the same cold-start warm-up to the CLI `run` (issue #569).

  - Add a reference-dataset regression test that runs production
    datasets through the v7.0.0 model and diffs against committed
    expected results (issue #385).

  - CI: run the test suite in parallel (`prove6 -j4`), bump typst to
    v0.15.0, fix the model-cache key, and drop unused LaTeX/Perl5
    components.


- 7.0.2, 2026-06-15, fritz.zaucker@oetiker.ch

  - Isolate the model precompilation cache per instance: ModelCache and
    the bin/agrammon.raku repo chain now honor `AGRAMMON_CACHE_DIR`
    (falling back to `~/.agrammon`), so test and prod instances sharing a
    HOME on one host can use separate caches and not perturb each other on
    deploy.

  - Build: keep the package version in sync with META6.json. Enable
    maintainer-mode so `make dist` re-runs autoconf when META6.json
    changes, plus a `check-version` guard that fails `make dist` if the
    configured version is stale.


- 7.0.1, 2026-06-15, fritz.zaucker@oetiker.ch

  - Fix crash when distributing a multi-instance livestock module
    (branching/flattening) while `dimensioning_barn` was left at its
    `Standard` default. Distribution now splits numeric totals
    proportionally (as before) and passes non-numeric sentinel values
    such as "Standard" through to each instance unchanged, where the
    module formula resolves them per instance.

- 7.0.0, 2026-05-19 and 2026-06-02, fritz.zaucker@oetiker.ch

  - Replace Spreadsheet::XLSX, LibXML and Inline::Perl5 based
    Excel exporter with custom native Raku exporter

  - Replaced LaTeX based PDF generator with Typst generator

  - Clean up version-related YAML fields.
    - `Database.version` is removed; `dataset.dataset_version` is now
      sourced from `Model.version` (the same identifier the version
      switcher matches against in `Versions[].version`). Frontend fade
      now compares like-with-like.
    - `Model.model` is removed (was never read by any code path).
    - New optional `GUI.version` field for the short user-visible
      version label (e.g. '7.0'). Exposed in `get_cfg` as `guiVersion`.
      Falls through to `Model.version` when not set.
    - `Versions[].label` is renamed to `Versions[].guiVersion`.

  - **Migration required** if you have datasets from before this
    change: see `db/migrate-dataset-version-source.sql`. Without
    migration, legacy datasets can be listed but not modified by the
    running deployment, because the `(user, name, variant)` lookup
    in store-variable won't find them.

  - New optional `Model.compatibleVersions` list — Model.version
    strings whose datasets this deployment will claim (promote to its
    own Model.version) on first open. Lets two sibling deployments
    share datasets without a manual migration step: opening a foreign-
    version dataset in the other deployment silently rewrites its
    `dataset_version`, making subsequent edits work normally. Set
    on both sides for round-trip editing. Empty/omitted = strict mode
    (only own version).

  - Fix DatasetVersion row renderer: themed font (was browser default),
    accessible mismatch color (was opacity-based, failed WCAG AA).

- 6.6.1, 2026-03-05, fritz.zaucker@oetiker.ch

  - Add bulk account creation via CSV file upload
    - Admin menu: "Upload accounts" button opens file upload dialog
    - REST API: POST /upload_accounts endpoint for programmatic access
    - CSV format: email, password (required), first, last, org (optional)
    - Returns list of created accounts and any errors
    - Available to admin and support role users

- 6.6.0, 2025-11-13, fritz.zaucker@oetiker.ch

- 6.5.3, 2025-05-27, fritz.zaucker@oetiker.ch

  - RT 60131: Fix pig default energy_content calculations

- 6.5.2, 2025-05-26, christoph.haenggi@bfh.ch

  - PR 601: Anpassungen Modell
     - technische Parameter
     - Modelländerungen unter anderem im Bereich Slurry

- 6.5.2, 2025-05-27, fritz.zaucker@oetiker.ch

  - RT 60131: Fix pig default energy_content calculations

- 6.5.1, 2025-03-31, fritz.zaucker@oetiker.ch
  - RT 59825: fix self service password reset
              fix minimum length requirement in GUI
  - reload on logout
  - localized activation mails
 
- 6.5.0, 2025-01-17, fritz.zaucker@oetiker.ch
  - RT 59314: defaults for Pig and Fattenpig excretion 
              and protein energy content
  - RT 57743: Possibly fix race condition leading to apparently
    simulation not changing after value change

- 6.4.2, 2024-12-04, fritz.zaucker@oetiker.ch
  - Fix RPC error handling (RT 59213)

- 6.4.1, 2024-11-22, fritz.zaucker@oetiker.ch
  - New Self Service for account creation and password reset

- 6.4.0, 2023-06-22, fritz.zaucker@oetiker.ch

  - Allow absolute path for --technical-file
  - Change GUI labels for pigs from grazing to outdoor
  - Allow grazing days > 270 days for dairy cows and other cattle
  - Add defaults (0) and validators ge(0) to Recycling Fertilizers
  - Check for unused technical parameters on documentation generation
  - Use ExcelFast (with Inline::Perl5)

- 6.3.0, 2022-06-23, fritz.zaucker@oetiker.ch

  - Add excel export to cmdline and REST
    including Excel export test script and data
  - RT 54044: fix Excel report generation performance
  - Issue 552: memory leak excel report identified and fixed
  - Issue 551: extend REST inputTemplate for json
  - Issue 550: implement compact json output with filters
  - Issue 549: fix CSV output with filters

  The followiung changes will change some simulation results:

  - fix model bug ignoring revised housing_type for poultry 
    emission rate
  - fix model bug ignoring NxOx emissions 
    for Label_Slurry_Open systems
  - fix regional model bug evaluating default_calc 
    instead of user selection for drop down selection
    (enums) -> see issue #539

- 6.2.1, 2022-03-09, fritz.zaucker@oetiker.ch

  - fix send dataset
  - fix handling of empty values with default value (Standard)

- 6.2.0, 2022-02-28, fritz.zaucker@oetiker.ch

  - add HAFL (lecture) report to single/regional model

- 6.1.5, 2022-02-04, fritz.zaucker@oetiker.ch

  - fix remove tag

- 6.1.4, 2022-01-11, fritz.zaucker@oetiker.ch

  - some cleanup

- 6.1.3, 2022-01-10, fritz.zaucker@oetiker.ch

  - fix regional model bug ignoring mitigation_housing_floor
    in dairy cows and other cattle
  - Update to Rakudo.2021-12

- 6.1.2, 2021-12-13, fritz.zaucker@oetiker.ch

  - fix handling of demo datasets
  - set session expiration to 2 hours
  - fix re-login on expired session
  - new menubar

- 6.1.1, 2021-09-13, fritz.zaucker@oetiker.ch

  - add web gui handling of default_formula
  - add getDataset command
  - LEAVE bug workaround
  - fix PDF log output
  - Write input validation errors to log

  Frontend
  - Disable upload button for none-admin users.
  - Improve upload error handling

- 6.0.1, 2021-08-19, fritz.zaucker@oetiker.ch

   - Fix some model errors

- 6.0.0, 2021-06-18, fritz.zaucker@oetiker.ch

   - Adapt to dataset changes
   - first official release
   - Add some REST routes

-  6.0.0-rc8, 2021-05-10, fritz.zaucker@oetiker.ch
   - Model changes

-  6.0.0-rc7, 2021-04-08, fritz.zaucker@oetiker.ch
   - Invalidate output cache on branch config change

-  6.0.0-rc6, 2021-04-01, fritz.zaucker@oetiker.ch
   - French GUI translations

-  6.0.0-rc5, 2021-03-31, fritz.zaucker@oetiker.ch
   - Small model fix
   - SummaryReport
   - Log division by 0 errors

-  6.0.0-rc4, 2021-03-30, fritz.zaucker@oetiker.ch
   - Fix dataset tagging
   - Fix recalc and report enabling
   - Enable report summary
   - Fix model warnings
   - Store branch config on instance copy

-  6.0.0-rc3, 2021-03-16, fritz.zaucker@oetiker.ch
   - Allow distribution of multiple inputs
     (e.g., animals and barn size)
   - More efficient/faster branching/flattening
   - Fix branching row/col order
   - Copy branching fractions on dataset clone
   - Handle simulation errors in frontend

-  6.0.0-rc2, 2021-03-05, fritz.zaucker@oetiker.ch
  - Fix branching over multiple sub modules
  - Fix flattening
  - Fix totals in branch editor
  - Fix defaults for flattened inputs

**This is not complete yet.**

- 6.0.0-rc1, 2021-02-25, fritz.zaucker@oetiker.ch
  - Web Application
    - Added upload of datasets from CSV files in dataset popups
    - Additional detailed result reports
    - Removed rarely used result reports
    - Removed result graphs
    - Removed result summary on input tag (temporarily)
  - Simulation model
    - Additional inputs:
      - bla
      - bla
    - Removed inputs:
      - bla
      - bla
  - Implementation
    - backend migrated from Perl5 to Raku
    - frontend upgraded to Qooxdoo 6.x
