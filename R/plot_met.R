#' Mapeo de las variables meterológicas
#'
#' Simple visualización de los datos meteorológicos que se desee.
#'
#' @param data data.frame obtenido al usar `meteoclimatic_download`.
#'
#' @return ggplot con la visualización de los datos deseados.
#'
#'




plot_met <- function(data, var = "Temp.max", pal = pals::jet(100),
                     units = "ºC", size = 3, alpha = 0.8, title = "",caption= "",...) {

  borders_esp <- raster::getData(name = "GADM", country = "ESP", level = 2)
  borders_pt <- raster::getData(name = "GADM", country = "PT", level = 0)
  borders_mar <-  raster::getData(name = "GADM", country = "MAR", level = 0)
  borders_alg <-  raster::getData(name = "GADM", country = "DZA", level = 0)

  esp_elev <- raster::getData("alt",country = "ESP", mask = T)
  pt_elev <- raster::getData("alt",country = "PT", mask = T)[[1]]
  elev <- raster::merge(esp_elev,pt_elev) %>%
    raster::aggregate(2) %>%
    raster::as.data.frame(xy = T) %>%
    setNames(c("lon","lat","Z")) %>%
    filter(!is.na(Z))

  borders_esp <- borders_esp %>%
    sf::st_as_sf()

  borders_pt <- borders_pt %>%
    sf::st_as_sf()

  borders_mar <- borders_mar %>%
    sf::st_as_sf()

  borders_alg <- borders_alg %>%
    sf::st_as_sf()

  ggplot()+
    geom_raster(data = elev, aes(lon,lat, fill = Z), interpolate = T,show.legend = F, alpha = 0.8)+
    scale_fill_gradientn(colors = grey.colors(100),na.value = "transparent")+
    ggnewscale::new_scale_fill() +
    geom_sf(data = borders_esp, fill = "transparent")+
    geom_sf(data = borders_pt, fill = "transparent")+
    geom_sf(data = borders_mar, fill = "grey")+
    geom_sf(data = borders_alg, fill = "grey")+
    geom_point(data = data, aes_string(x = "lon", y = "lat",  fill = var),pch = I(21), size = size, alpha = alpha)+
    scale_fill_gradientn(colors = pal) +
    scale_x_continuous(limits = c(min(data$lon)-0.1,c(max(data$lon))+0.1),expand = c(0,0))+
    scale_y_continuous(limits = c(min(data$lat)-0.1,c(max(data$lat))+0.1),expand = c(0,0))+
    theme_bw() +
    labs(title = title, caption = )+
    theme(axis.title = element_blank(),
          legend.position = "bottom")+
    guides(fill = guide_colorbar(title = "ºC",
                                 label.position = "bottom",
                                 title.position = "left", title.vjust = 1,
                                 # draw border around the legend
                                 frame.colour = "black",
                                 barwidth = 15,
                                 barheight = 1.25))
}
