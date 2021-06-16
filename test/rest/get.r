library(httr)
library(jsonlite)
url = "https://model.agrammon.ch/single/test/api/v1/greet"
apitoken = "agm_FJaYpucVh9sawvZChLSi5pVeN9qRR8XAHbaWGVkmqEHq0Ev57OfFat+F384="

response <- GET(url, add_headers(Authorization = paste("Bearer", apitoken, sep = " " )))

print(response)

a <- jsonlite::fromJSON(content(response, "text"))

print(a)
