######################################################################
## This script: (1) requests and stores json from the jcdecaux API;
## (2) downloads Seville city's boundaries; (3) formats and plots.
######################################################################

# libraries
library(jsonlite)
library(tidyverse)
library(sf)
library(httr)
library(ggthemes)
library(lubridate)

if (!dir.exists("./decaux")) dir.create("./decaux")  ## folder to store requests

key <- ""  ## store API key

request <- httr::GET(
        paste0("https://api.jcdecaux.com/vls/v1/stations?contract=Seville&apiKey=", key)
)

if (status_code(request) != 200) {
        stop(paste("Client/server error.", "Status =", status_code(request)))
}

req_content <- httr::content(request, as = "text", encoding = "UTF-8")  ## Get the content as text. keep json structure


day_hour <- format.POSIXct(as.POSIXct(Sys.time(), tz = "Europe/Madrid"), "%Y-%m-%e %H-%M", tz = "Europe/Madrid")  ## Create date-time to identify request

write(req_content, file = paste0("./decaux/", day_hour, ".json"))  ## Save request content

req_list <- list.files("./decaux", full.names = TRUE)
json_data <- lapply(req_list, function(x) fromJSON(txt = readLines(x), flatten = TRUE))  ## convert from json, and get back list of data frames

json_list_df <- function(x) {
        
        list_dfs <- vector(mode = "list", length = length(x))
        
        for (i in seq_along(x)) {
                x[[i]]$req_time <- lubridate::ymd_hm(req_list[[i]], tz = "Europe/Madrid")
                list_dfs[[i]] <- x[[i]]
        }
        
        dplyr::bind_rows(list_dfs)
}

parent_df <- json_list_df(json_data)

# rename, modify and add columns
parent_df <- parent_df %>%
        rename(lat = position.lat, long = position.lng) %>% 
        select(-c(banking, bonus, contract_name))

parent_df <- mutate(parent_df, prop_uso = round(available_bike_stands/(available_bike_stands + available_bikes), digits = 2),
                                  last_update = as.POSIXct(parent_df$last_update/1000, origin = "1970-01-01", tz = "Europe/Madrid"))

parent_df <- arrange(parent_df, desc(req_time))

# convert to sf object
parent_df <- st_as_sf(parent_df, crs = 4326, coords = c("long", "lat"))

# map neighbourhoods of Seville and see locations of stations
barrios <- st_read("http://sevilla-idesevilla.opendata.arcgis.com/datasets/38827fc3eac142149801c2efa2a0bdf9_0.geojson", stringsAsFactors = FALSE) %>%
        st_as_sf(crs = 4326, coords = c("long", "lat"))

barrios_bicis <- sf::st_join(parent_df, barrios, join = st_within) %>% arrange(desc(req_time))  # spatial join. Allows to know which neighbourhood each point belongs to

barrios_bicis$DISTRITO_N <- sub("-+", "\n", barrios_bicis$DISTRITO_N)  # add line breaks with plots in mind

# Map of usage of the last request
bicis_mapa <- ggplot() +
        geom_sf(data = parent_df[1:257, ], 
                   aes(colour = prop_uso), size = 1.5) +
        scale_color_viridis_c(
                name = "Proporción [0, 1]",
                guide = guide_colourbar(title.position = "top", title.hjust = 0.5)
        ) +
        geom_sf(data = barrios, fill = NA) +
        coord_sf(datum = NA, xlim = c(-5.9, -6.05), ylim = c(37.44, 37.32)) +
        theme(
                legend.justification = "center",
                legend.position = "bottom",
                legend.key.width = unit(x = 0.8, units = "cm")
        ) +
        labs(title = "Bicis en uso en estaciones SEVici\ndel Municipio de Sevilla",
             subtitle = paste("Fecha y hora:", lubridate::ymd_hms(parent_df$req_time[1])))

# geom_point faceted to districts in last request
distritos_puntos <- ggplot(barrios_bicis[1:257, ]) +
  geom_point(aes(x = req_time, y = prop_uso), colour = "#005083") +
  scale_y_continuous(limits = c(0, 1)) +
  facet_grid(~DISTRITO_N) +
  theme_fivethirtyeight() +
  theme(
    axis.text.x = element_blank(),
    panel.grid.major.x = element_line(colour = NA),
    plot.caption = element_text(size = 11)
  ) +
  labs(caption = strftime(barrios_bicis$req_time[[1]], "Obtenido el %e de %B del %Y, a las %R", tz = tz(barrios_bicis$req_time)))

# Dot plot of usage of a given station through time. Meant to be used with many repeated requests
estacion_point <- 
        parent_df[parent_df$number == 19, ] %>%
        mutate(year_month = format(req_time, "%Y-%m")) %>% 
        ggplot() +
        geom_point(aes(x = as.factor(format(req_time, "%d-%H:%M")), y = prop_uso)
        ) +
        scale_x_discrete(drop = TRUE) +
        scale_y_continuous(limits = c(0, 1)) +
        facet_wrap(~ year_month) +
        theme_fivethirtyeight() +
        theme(
                axis.title = element_blank(),
                axis.text.x = element_text(angle = 45, vjust = .5)
        ) +
        labs(title = paste("Prop. uso estación:", parent_df[parent_df$number == 19, "name"][[1]]))

