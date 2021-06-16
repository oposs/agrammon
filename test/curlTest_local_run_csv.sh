curl  \
     -F "dataset=Hochrechung2021" \
     -H "Content-Type: multipart/form-data" \
     -H 'Authorization: Bearer agm_G2DzwdBc2BNOqLmQzd9irdK26UXcKkJuWlJ9qmvqxjkjhFyxlHcwB240Dxk=' \
     -F 'inputs=@testData.csv;type=text/csv' \
   http://localhost:20000/api/v1/run

#    | json_pp
