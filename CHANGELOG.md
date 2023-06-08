- current
  
  - Allow absolute path for --technical-file
  - Change GUI labels for pigs from grazing to outdoor
  - Allow grazing days > 270 days for dairy cows and other cattle
  - Add defaults (0) and validators ge(0) to Recycling Fertilizers

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
