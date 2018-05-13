# libraries
library(jsonlite); library(tidyverse); library(sf); library(httr); library(ggthemes); library(lubridate)

if (!dir.exists("./queries")) {dir.create("./queries")} # create folder where to store requests

request <- httr::GET(
        "https://api.citybik.es/v2/networks/sevici?fields=stations")  # check https://api.citybik.es/v2/ 

if (status_code(request) != 200) {
        stop(paste("Client/server error.", "Status =", status_code(request)))
}

req_content <- httr::content(request, as = "text", encoding = "UTF-8") # Get the content as text. keep json structure

day_hour <- strftime(Sys.time(), format = "%Y-%m-%e,%H.%M")  # Create relative names to uniquely name each request text

write(req_content, file = paste0("./queries/", day_hour, ".json"))  # Save request content

req_list <- list.files("./queries", full.names = TRUE)
json_data <- lapply(req_list, function(x) fromJSON(txt = x, flatten = TRUE))  # iterate over each, and get back unnested data frames

json_list_df <- function(x) {
        
  list_dfs <- vector(mode = "list", length = length(json_data))
  
  for (i in seq_along(json_data)) {
    list_dfs[[i]] <- json_data[[i]][["network"]][["stations"]] # get "stations" field. It's a data frame with stations info
  }

  dplyr::bind_rows(list_dfs)
}

parent_df <- json_list_df(json_data)
parent_df <- parent_df %>% mutate(prop_uso = round(empty_slots/(empty_slots + free_bikes), digits = 2))

# map neighbourhoods of Seville and see locations of stations
barrios <- st_read("http://sevilla-idesevilla.opendata.arcgis.com/datasets/38827fc3eac142149801c2efa2a0bdf9_0.geojson", stringsAsFactors = FALSE) %>%
  st_as_sf(crs = 4326, coords = c("long", "lat"))

ggplot() +
  geom_point(data = parent_df[(nrow(parent_df) - 257):nrow(parent_df), ], 
             aes(x = longitude, y = latitude, colour = prop_uso), size = 1.5) +
  scale_color_viridis_c(
    name = "Proporción [0, 1]",
    guide = guide_colourbar(title.position = "top", title.hjust = 0.5)
  ) +
  geom_sf(data = barrios_limits, fill = NA) +
  coord_sf(datum = NA, xlim = c(-5.9, -6.05), ylim = c(37.44, 37.32)) +
  theme_fivethirtyeight() +
  theme(
    legend.justification = "center",
    legend.key.width = unit(x = 1, units = "cm")
  ) +
  labs(title = "Bicis en uso en estaciones SEVici\ndel Municipio de Sevilla",
       subtitle = paste("Fecha y hora:", lubridate::ymd_hms(parent_df$timestamp, tz = "Europe/Madrid")[nrow(parent_df)]))


