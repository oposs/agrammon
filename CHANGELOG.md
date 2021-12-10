# Agrammon Change Log

- 6.1.2, 2021-12-09, fritz.zaucker@oetiker.ch

  - fix handling of demo datasets
  - fix re-login on expired session
  - instrument frontend for GUI testing

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
