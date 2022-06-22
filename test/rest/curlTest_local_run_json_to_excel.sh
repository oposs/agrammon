#!/usr/bin/env bash
curl \
     -H "Content-Type: multipart/form-data" \
     -H "Accept: text/csv" \
     -H 'Authorization: Bearer agm_N2SR5yjT4ydTnjAw/9yd+vnd/BxLD8/wr5TMcgEwATnHzr+4V7mLkxxwYYM=' \
     -F "variants=Base" \
     -F "model=version6" \
     -F "technical=technical.cfg" \
     -F "simulation=FritzTest" \
     -F "dataset=Hochrechung2021" \
     -F "language=de" \
     -F "inputs=@$1;type=application/json" \
    http://localhost:20000/single/test/api/v1/run

#    https://model.agrammon.ch/singleRest/api/v1/run
#     -F "report-selected=0" \
#     -H "Accept: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" \
