curl  \
     -H "Content-Type: multipart/form-data" \
     -H "Accept: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" \
     -H 'Authorization: Bearer agm_N2SR5yjT4ydTnjAw/9yd+vnd/BxLD8/wr5TMcgEwATnHzr+4V7mLkxxwYYM=' \
     -F "variants=Base" \
     -F "model=version6" \
     -F "technical=technical.cfg" \
     -F "report-selected=1" \
     -F "include-filters=true" \
     -F "compact-output=$2" \
     -F "simulation=FritzTest" \
     -F "dataset=Hochrechung2021" \
     -F "language=de" \
     -F "inputs=@$1;type=text/csv" \
     --output - \
   http://localhost:20000/api/v1/run

#    | json_pp
#     -F "compact-output=false" \
#     -H "Accept: application/json" \
