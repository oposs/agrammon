curl  \
     -H "Content-Type: multipart/form-data" \
     -H "Accept: text/plain" \
     -H 'Authorization: Bearer agm_N2SR5yjT4ydTnjAw/9yd+vnd/BxLD8/wr5TMcgEwATnHzr+4V7mLkxxwYYM=' \
     -F "variants=Base" \
     -F "model=version6" \
     -F "print-only=SummaryTotal" \
     -F "technical=technical2010.cfg" \
     -F "simulation=FritzTest" \
     -F "dataset=Hochrechung2021" \
     -F "language=de" \
     -F 'inputs=@testDataFull.json;type=application/json' \
   http://localhost:20000/api/v1/run

#    | json_pp
