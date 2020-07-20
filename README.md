meteoclimaticR <img src="img/logo.png" align="right" alt="" width="140" />
=========================================================
# `meteoclimaticR`: Descarga de datos de Meteoclimatic (https://www.meteoclimatic.net/)

## Descripción

**meteoclimaticR** permite la descarga de datos meteorológicos proporcionados por la red de Meteoclimatic. Se pueden obtener los datos actuales de temperatura, humedad relativa, precipitación, viento y presión atmosférica. Además también se pueden descargar los valores máximos y mínimos del mismo día. Como nota negativa, no se pueden bajar datos históricos, solamente los del presente día. 

## ¿Cómo funciona?

### Instalación

``` r
# Descarga desde github (0.0.1):
# install.packages("remotes")
remotes::install_github("lemuscanovas/meteoclimaticR")
```

### ejemplo 1

Para la descarga de datos de la **província de Barcelona**, es necesario escribir el **identificador** (`id_prov`) común para todas las estaciones de esta región. Este `id_prov` lo podemos obtener consultando cualquier estación de la provincia, por ejemplo Barcelona - Tibidabo (**ESCAT080000000**8023C). El texto en negrita hace referencia al identificador común de la provincia de Barcelona. **El identificador termina cuando aparece la primera cifra distinta a 0**
