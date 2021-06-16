library(httr)
library(jsonlite)
url = "https://model.agrammon.ch/single/test/api/v1/echo"
apitoken = "agm_FJaYpucVh9sawvZChLSi5pVeN9qRR8XAHbaWGVkmqEHq0Ev57OfFat+F384="

body = list(foo = "bar", dataset = "Hochrechnung" )
response <- POST(url, add_headers(Authorization = paste("Bearer", apitoken, sep = " " )), body = body, encode = "json" )

print(response)

a <- jsonlite::fromJSON(content(response, "text"))

print(a)
