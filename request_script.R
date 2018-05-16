# libraries
library(tidyverse)
library(httr)

if (!dir.exists("./decaux")) {
  dir.create("./decaux")
} # create folder where to store requests

for (i in seq_along(5*2)) { # every 1/2 hour for 5 hours
  request <- httr::GET(
    "https://api.jcdecaux.com/vls/v1/stations?contract=Seville&apiKey=90f096efd2e83e1711874c7a60324e41361b964b"
  )
  while (status_code(request) != 200) {
    request <- httr::GET(
      "https://api.jcdecaux.com/vls/v1/stations?contract=Seville&apiKey=90f096efd2e83e1711874c7a60324e41361b964b"
    )

    Sys.sleep(300)  # if request fails repeat every 5 minutes
  }

  req_content <- httr::content(request, as = "text", encoding = "UTF-8") # Get the content as text. keep json structure

  day_hour <- format.POSIXct(Sys.time(), "%Y-%m-%e %H-%M", tz = "Europe/Madrid") # Create date-time to name each request

  write(req_content, file = paste0("./decaux/", day_hour, ".json")) # Save request content
  
  Sys.sleep(1800)  # put to sleep for 30 minutes between each iteration
}

