#! /bin/bash
raku -Ilib bin/agrammon.pl6 --export-filename=text.xlsx --format=excel \
    --include-filters --include-all-filters --report-selected=1 \
    run \
    version6/End.nhd t/test-data/Inputs/HR_2015_cmdline.csv
