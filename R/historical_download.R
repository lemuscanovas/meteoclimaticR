#' Download daily historical records from Meteoclimatic
#'
#' @description \code{historical_download} allows to download all the historical
#' daily Meteoclimatic database. Records starts in 2012.
#'
#' @param id character. Id of the CCAA, used by Meteoclimatic. Default "ESIBA" Balearic Islands.
#' @param dates character. Starting and ending date. Alternatively, a unique date is also allowed.
#' @param months numeric. Optional. Month subset Only applies for ranges of dates.
#' @param save_excel logical. Save the downloaded database in an Excel file
#'
#' @return A list with: \itemize{
#'    \item{A data.frame containing georreferenced daily meteorological values for all the stations located in the requested CCAA.
#' }}
#'
#' @examples
#' historical_data <- historical_download(id = "ESIBA",
#' dates = c("2021-05-16","2021-07-15"),
#' save_excel = FALSE)
#'
#' @seealso  \code{\link{current_download}}
#'
#' @import tidyr
#' @import dplyr
#' @import rvest
#' @import XML
#' @importFrom stringr str_detect str_remove str_replace
#' @import lubridate
#' @import progress
#' @import httr
#' @import openxlsx
#' @importFrom stats setNames

#'
#' @export

historical_download <- function(id = "ESIBA", dates = c("2021-05-16","2021-07-15"),
                                months = c(1:12), save_excel = TRUE){
  if(length(dates) == 1){
    seq_dates <- dates
    } else {
      dates <- as_date(dates)
      seq_dates <- seq.Date(from = dates[1],to = dates[2],by = "day")
      seq_dates <- seq_dates[which(month(seq_dates) %in% months)]
      }

  pb <- progress_bar$new(
    format = "  downloading [:bar] :percent eta: :eta",
    total = length(seq_dates), clear = FALSE, width= 60)


  series <- list()
  for (dd in seq_along(seq_dates)) {
    pb$tick()
    Sys.sleep(1 / 100)
    data <- seq_dates[dd]
    website <- read_html(paste0("https://www.meteoclimatic.net/mapinfo/",
                                id,"?d=",str_remove(str_remove(data,"-"),"-")))

    dictionary <- data.frame(idx = c("ESCAT", # cat
                        "ESPVA", #val
                        "ESMUR", # mur
                        "ESAND", # and
                        "PTSUR","PTCEN","PTNOR", # pt
                        "ESEXT", #ext
                        "ESCLM", #cylam
                        "ESMAD", #mad
                        "ESCYL", #cyleo
                        "ESGAL", # gal
                        "ESAST", #astu
                        "ESCTB" ,#cant
                        "ESEUS", #eusk
                        "ESNAF", #nav,
                        "ESLRI", #rioj
                        "ESARA", #arag
                        "ESIBA"),
               n = c(4,3,1,8,2,3,2,2,5,1,9,4,1,1,3,1,1,3,3))

    index <- filter(dictionary, id == .data$idx)%>% select(n) %>% pull() # n provs

    #DESCARREGA HISTORIC

    tab_data <- list()
    for (ii in 1:index) {

    tab <- website %>%
      html_nodes("table") %>%
      .[[7+ii]] %>%
      html_table(fill = T,header = T,convert = T,dec = ",") %>%
      setNames(c(1:ncol(.))) %>%
      select(-c(1,4,7,10,13,16,17)) %>%
      setNames(c("name_tab","alt","Temp.max","Temp.min","Hum.max","Hum.min",
                 "Pres.max","Pres.min","Vient.max","Precip.diaria")) %>%
      slice(-1) %>%
      mutate_at(.vars = vars(.data$Pres.min, .data$Pres.max),
                .funs = function(x)(str_replace(x,"1.","1"))) %>%
      mutate_at(.vars = vars(.data$Temp.max,.data$Temp.min,
                             .data$Hum.max,.data$Precip.diaria),
                .funs =function(x)(str_replace(x,",","."))) %>%
      mutate(Precip.diaria = ifelse(.data$Precip.diaria == "-",0,
                                    .data$Precip.diaria)) %>%
      mutate_at(.vars = vars(.data$alt:.data$Precip.diaria),.funs = as.numeric)
    tab_data[[ii]] <- tab
    }

    tab_data <- bind_rows(tab_data)
    ## COORDENADES BASE ACTUAL
    xml.lonlat <- paste0("http://meteoclimatic.com/feed/rss/",id) # lon lat
    lonlat <- xmlParse(rawToChar(GET(xml.lonlat)$content))
    lonlat.l <- t(xmlToList(lonlat, simplify = TRUE))

    coords <- lonlat.l[11:length(lonlat.l)-1]
    coords<- tibble(coord = coords)

    coords <-coords %>%
      unnest_wider(.data$coord) %>% select(.data$title, .data$link,
                                           .data$pubDate,.data$point) %>%
      mutate(link = str_replace(.data$link, "http://www.meteoclimatic.net/perfil/","")) %>%
      separate(.data$pubDate,into = c("weekday", "num", "month",
                                "yr", "hour", "trash"),sep = " ") %>%
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
             lon = ifelse(.data$lon >4 & .data$lat > 40.5,-.data$lon,.data$lon)) %>%
      mutate(time = as_date(data))

    coords <- select(coords, .data$name, .data$id,.data$time, .data$lon,.data$lat)

    dada_geo <- full_join(mutate(coords, i=1),
              mutate(tab_data, i=1),by = "i") %>%
      select(-.data$i) %>%
      filter(str_detect(.data$name, .data$name_tab)) %>%
      distinct(.data$name ,.keep_all = T) %>%
      relocate(.data$name_tab, .before = .data$name) %>%
      select(-.data$name) %>% rename(name = .data$name_tab)

    series[[dd]] <- dada_geo
  }
  serie <- bind_rows(series)

  if(isTRUE(save_excel)){
    openxlsx::write.xlsx(serie, paste0(id,"_hist.xlsx"))
    message("data stored in:",getwd())
  }
  return(serie)
}
