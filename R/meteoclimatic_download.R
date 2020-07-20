#' Descarga de datos de Meteoclimatic
#'
#' Esta función permite bajar todos los valores de temperatura, precipitación, humedad,
#' viento y presión por provincia.
#' 
#' @param id_prov Identificador de Provincia facilitado por Meteoclimatic. Ej. Barcelona: ESCAT080000000.
#' 
#' @return data.frame xy con todos los valores de las variables registradas por las estaciones de la província solicitada
#' 
#' @details Se pueden obtener datos actuales, máximos y mínimos por estación. Sin embargo, no se pueden descargar datos históricos.
#' 

meteoclimatic_download <- function(id_prov = "ESCAT080000000") {

  data_final <- list()
  for (id in id_prov) {
    xml.lonlat <- paste0("http://meteoclimatic.com/feed/rss/",id) # lon lat
    lonlat <- xmlParse(rawToChar(GET(xml.lonlat)$content))
    lonlat.l <- t(xmlToList(lonlat, simplify = TRUE))
    
    
    
    coords <- lonlat.l[11:length(lonlat.l)-1]
    coords<- tibble(coord = coords)
    
    coords <-coords %>%
      unnest_wider(coord) %>% select(title, link, pubDate,point) %>%
      mutate(link = str_replace(link, "http://www.meteoclimatic.net/perfil/","")) %>%
      separate(pubDate,into = c("dia_semana", "num", "mes", "año", "hora", "basura"),sep = " ") %>%
      select(-dia_semana,-basura) %>%
      separate(point, into = c("lat","lon"), sep = " ") %>% rename(name = title,
                                                                   id = link) %>%
      mutate(lat = as.numeric(lat),
             lon =as.numeric(lon))%>%
      mutate(lat2 = ifelse(lat < 10, lon, lat ),
             lon2 = ifelse(lon >10, lat,lon)) %>%
      select(-c(lat:lon)) %>%
      rename(lat = lat2,
             lon = lon2) %>%
      mutate(lon = ifelse(lon >2 & lat<38,-lon,lon),
             lon = ifelse(lon >1 & lat>43,-lon,lon),
             lon = ifelse(lon >4 & lat > 40.5,-lon,lon))
    
    
    xml.data <- paste0("http://www.meteoclimatic.net/feed/xml/",id) # data
    data <- xmlParse(rawToChar(GET(xml.data)$content))
    data.l <- t(xmlToList(data, simplify = TRUE))
    
    meteo <- data.l[[7]][2:length(data.l[[7]])]
    meteo<- tibble(met = meteo)
    
    meteo_id <-meteo %>%
      unnest_wider(met) %>% select(id)
    
    meteo_temp <-meteo %>%
      unnest_wider(met) %>% select(stationdata) %>%
      unnest_wider(stationdata) %>%
      unnest_wider(temperature) %>% rename("Temp.unit" = unit,"Temp.act" = now, "Temp.max" = max, "Temp.min" = min) %>%
      select(Temp.unit, Temp.act, Temp.max, Temp.min)
    
    meteo_hum <-meteo %>%
      unnest_wider(met) %>% select(stationdata) %>%
      unnest_wider(stationdata) %>%
      unnest_wider(humidity) %>% rename("Hum.unit"= unit,"Hum.act" = now, "Hum.max" = max, "Hum.min" = min) %>% 
      select(Hum.unit, Hum.act, Hum.max, Hum.min)
    
    meteo_pres <-meteo %>%
      unnest_wider(met) %>% select(stationdata) %>%
      unnest_wider(stationdata) %>%
      unnest_wider(barometre) %>% rename("Pres.unit"= unit,"Pres.act" = now, "Pres.max" = max, "Pres.min" = min) %>% 
      select(Pres.unit,Pres.act,Pres.max,Pres.min) 
    
    meteo_wind <-meteo %>%
      unnest_wider(met) %>% select(stationdata) %>%
      unnest_wider(stationdata) %>%
      unnest_wider(wind) %>% rename("Vient.unit"= unit,"Vient.act" = now, "Vient.dir" = azimuth, "Vient.max" = max) %>% 
      select(Vient.unit,Vient.act,Vient.dir,Vient.max) 
    
    meteo_precip <-meteo %>%
      unnest_wider(met) %>% select(stationdata) %>%
      unnest_wider(stationdata) %>%
      unnest_wider(rain) %>% rename("Precip.unit"= unit,"Precip.total" = total)%>% 
      select(Precip.unit,Precip.total) 
    
    
    full_data <- inner_join(coords, bind_cols(meteo_id,meteo_temp, meteo_hum, meteo_pres, meteo_wind, meteo_precip), by = "id")   
    full_data <- mutate_at(full_data,.vars = vars(num, año,Temp.act,Temp.max,Temp.min,Hum.act,Hum.max,Hum.min,Pres.act, Pres.max, Pres.min,
                                                  Vient.act,Vient.dir,Vient.max,Precip.total), .funs = as.numeric)
    
    full_data$name <- iconv(full_data$name, from="UTF-8", to="LATIN1")
    data_final[[id]] <- full_data
  }
  
  fin <- bind_rows(data_final)
  
  return(fin)

}