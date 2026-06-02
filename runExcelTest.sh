#! /bin/bash
raku -Ilib bin/agrammon.raku --cfg-file=etc/agrammon-excel-test.cfg.yaml \
    --export-filename=text.xlsx --format=excel \
    --include-filters --include-all-filters --report-selected=1 \
    run \
    version6/End.nhd t/test-data/Inputs/HR_2015_cmdline.csv
