curl  \
     -F "technical=technical2010.cfg" \
     -F "simulation=FritzTest" \
     -F "dataset=Hochrechung2021" \
     -F "format=text/plain" \
     -F "language=de" \
     -F "prints=SummaryTotal" \
     -H "Content-Type: multipart/form-data" \
     -H 'Authorization: Bearer agm_N2SR5yjT4ydTnjAw/9yd+vnd/BxLD8/wr5TMcgEwATnHzr+4V7mLkxxwYYM=' \
     -F 'inputs=@restDataFull.csv;type=text/csv' \
   http://localhost:20000/api/v1/run

#    | json_pp
