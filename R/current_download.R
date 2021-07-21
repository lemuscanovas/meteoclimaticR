#' @title Download the latest data from Meteoclimatic
#'
#' @description \code{current_download} allows to download all the latest daily meteorological from the Meteoclimatic network.
#'
#' @param id character. Id of the CCAA, province or station, used by Meteoclimatic. Default: "ESCAT080000000". Province of Barcelona.
#' @param save_excel logical. Do you want to save the downloaded data in an Excel file?
#'
#' @return A list with: \itemize{
#'    \item{A data.frame containing georreferenced daily meteorological values for all the stations located in the requested id
#' }}
#'
#' @examples
#' latest_data <- current_download(id = "ESCAT080000000", save_excel = FALSE)
#'
#' @seealso  \code{\link{historical_download}}
#'
#' @export


current_download <- function(id = "ESCAT080000000", save_excel = TRUE) {

  data_final <- list()
  for (ii in id) {
    xml.lonlat <- paste0("http://meteoclimatic.com/feed/rss/",ii) # lon lat
    lonlat <- xmlParse(rawToChar(GET(xml.lonlat)$content))
    lonlat.l <- t(xmlToList(lonlat, simplify = TRUE))



    coords <- lonlat.l[11:length(lonlat.l)-1]
    coords<- tibble(coord = coords)

    coords <-coords %>%
      unnest_wider(.data$coord) %>% select(.data$title, .data$link,
                                           .data$pubDate,.data$point) %>%
      mutate(link = str_replace(.data$link,
                                "http://www.meteoclimatic.net/perfil/","")) %>%
      separate(.data$pubDate,
               into = c("weekday", "num", "month", "yr", "hour", "trash"),
               sep = " ") %>%
      select(-.data$weekday,-.data$trash) %>%
      separate(.data$point, into = c("lat","lon"), sep = " ") %>%
      rename(name = .data$title, id = .data$link) %>%
      mutate(lat = as.numeric(.data$lat),
             lon =as.numeric(.data$lon))%>%
      mutate(lat2 = ifelse(.data$lat < 10, .data$lon, .data$lat ),
             lon2 = ifelse(.data$lon >10, .data$lat,.data$lon)) %>%
      select(-c(.data$lat:.data$lon)) %>%
      rename(lat = .data$lat2,
             lon = .data$lon2) %>%
      mutate(lon = ifelse(.data$lon >2 & .data$lat<38,-.data$lon,.data$lon),
             lon = ifelse(.data$lon >1 & .data$lat>43,-.data$lon,.data$lon),
             lon = ifelse(.data$lon >4 & .data$lat > 40.5,-.data$lon,.data$lon))


    xml.data <- paste0("http://www.meteoclimatic.net/feed/xml/",ii) # data
    data <- xmlParse(rawToChar(GET(xml.data)$content))
    data.l <- t(xmlToList(data, simplify = TRUE))

    meteo <- data.l[[7]][2:length(data.l[[7]])]
    meteo<- tibble(met = meteo)

    meteo_id <-meteo %>%
      unnest_wider(.data$met) %>% select(.data$id)

    meteo_temp <-meteo %>%
      unnest_wider(.data$met) %>% select(.data$stationdata) %>%
      unnest_wider(.data$stationdata) %>%
      unnest_wider(.data$temperature) %>%
      rename("Temp.unit" = .data$unit,
             "Temp.act" = .data$now,
             "Temp.max" = .data$max,
             "Temp.min" = .data$min) %>%
      select(.data$Temp.unit, .data$Temp.act, .data$Temp.max, .data$Temp.min)

    meteo_hum <-meteo %>%
      unnest_wider(.data$met) %>% select(.data$stationdata) %>%
      unnest_wider(.data$stationdata) %>%
      unnest_wider(.data$humidity) %>%
      rename("Hum.unit"= .data$unit,
             "Hum.act" = .data$now,
             "Hum.max" = .data$max,
             "Hum.min" = .data$min) %>%
      select(.data$Hum.unit, .data$Hum.act,
             .data$Hum.max, .data$Hum.min)

    meteo_pres <-meteo %>%
      unnest_wider(.data$met) %>% select(.data$stationdata) %>%
      unnest_wider(.data$stationdata) %>%
      unnest_wider(.data$barometre) %>%
      rename("Pres.unit"= .data$unit,
             "Pres.act" = .data$now,
             "Pres.max" = .data$max,
             "Pres.min" = .data$min) %>%
      select(.data$Pres.unit,.data$Pres.act,.data$Pres.max,.data$Pres.min)

    meteo_wind <-meteo %>%
      unnest_wider(.data$met) %>% select(.data$stationdata) %>%
      unnest_wider(.data$stationdata) %>%
      unnest_wider(.data$wind) %>%
      rename("Vient.unit"= .data$unit,
             "Vient.act" = .data$now,
             "Vient.dir" = .data$azimuth,
             "Vient.max" = .data$max) %>%
      select(.data$Vient.unit,.data$Vient.act,.data$Vient.dir,.data$Vient.max)

    meteo_precip <-meteo %>%
      unnest_wider(.data$met) %>% select(.data$stationdata) %>%
      unnest_wider(.data$stationdata) %>%
      unnest_wider(.data$rain) %>%
      rename("Precip.unit"= .data$unit,
             "Precip.total" = .data$total)%>%
      select(.data$Precip.unit,.data$Precip.total)


    full_data <- inner_join(coords, bind_cols(meteo_id,
                                              meteo_temp,
                                              meteo_hum,
                                              meteo_pres,
                                              meteo_wind,
                                              meteo_precip), by = "id")

    full_data <- mutate_at(full_data,.vars = vars(.data$num,
                                                  .data$yr,
                                                  .data$Temp.act,
                                                  .data$Temp.max,
                                                  .data$Temp.min,
                                                  .data$Hum.act,
                                                  .data$Hum.max,
                                                  .data$Hum.min,
                                                  .data$Pres.act,
                                                  .data$Pres.max,
                                                  .data$Pres.min,
                                                  .data$Vient.act,
                                                  .data$Vient.dir,
                                                  .data$Vient.max,
                                                  .data$Precip.total),
                           .funs = as.numeric)

    full_data$name <- iconv(full_data$name, from="UTF-8", to="LATIN1")
    data_final[[id]] <- full_data
  }

  fin <- bind_rows(data_final)
  if(isTRUE(save_excel)){
    write.xlsx(fin, "meteoclimatic_latest.xlsx")
    message("data stored in:",getwd())
  }
  return(fin)

}
