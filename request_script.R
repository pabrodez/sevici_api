######################################################################
## This script requests and stores json files from the jcdecaux API
## every 30 mins
######################################################################

# libraries
library(jsonlite)
library(tidyverse)
library(httr)

# folders
if (!dir.exists("./decaux")) dir.create("./decaux")

# loop to request and write json file containing info on bike stations at time of request via jcdecaux api
for (i in seq_len(10)) { # every 1/2 hour for 5 hours. This can be changed as wanted
  request <- httr::GET(
    "https://api.jcdecaux.com/vls/v1/stations?contract=Seville&apiKey=90f096efd2e83e1711874c7a60324e41361b964b"
  )
  while (status_code(request) != 200) {
    request <- httr::GET(
      "https://api.jcdecaux.com/vls/v1/stations?contract=Seville&apiKey=90f096efd2e83e1711874c7a60324e41361b964b"
    )

    Sys.sleep(300)  ## repeat every 5 mins while requests fails
  }

  req_content <- httr::content(request, as = "text", encoding = "UTF-8")  ## get the content as text and keep json structure

  day_hour <- format.POSIXct(as.POSIXct(Sys.time(), tz = "Europe/Madrid"), "%Y-%m-%e %H-%M", tz = "Europe/Madrid")  ## create date-time to name each request

  write(req_content, file = paste0("./decaux/", day_hour, ".json"))  ## save request content
  
  Sys.sleep(1800)  ## sleep for 30 mins
}

