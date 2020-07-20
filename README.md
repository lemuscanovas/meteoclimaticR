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

Para la descarga de datos de la **província de Barcelona**, usaremos la función `meteoclimatic_download`.  Para su funcionamiento es necesario escribir el **identificador** (`id_prov`) común para todas las estaciones de esta provincia. Este `id_prov` lo podemos obtener consultando cualquier estación de la provincia, por ejemplo Barcelona - Tibidabo (**ESCAT080000000**8023C). El texto en negrita hace referencia al identificador común de la provincia de Barcelona. **El identificador termina cuando aparece la primera cifra distinta a 0**


``` r
# Cargamos las librerías necesarias para el funcionamiento de la función:
if(!require("tidyverse")) install.packages("tidyverse")
if(!require("httr")) install.packages("httr")
if(!require("XML")) install.packages("XML")
if(!require("raster")) install.packages("raster")
if(!require("sf")) install.packages("sf")


# Descarga de los datos de temperatura máxima de la Provincia de Barcelona
bcn_met <- meteoclimatic_download(id_prov = "ESCAT080000000")

# A tibble: 181 x 26
   name  id      num mes     año hora    lat   lon Temp.unit Temp.act Temp.max Temp.min Hum.unit Hum.act Hum.max Hum.min Pres.unit Pres.act Pres.max
   <chr> <chr> <dbl> <chr> <dbl> <chr> <dbl> <dbl> <chr>        <dbl>    <dbl>    <dbl> <chr>      <dbl>   <dbl>   <dbl> <chr>        <dbl>    <dbl>
 1 Aigu~ ESCA~    20 Jul    2020 17:5~  41.8  2.25 C             26.5     31       15.3 %             65      91      37 hPa          1018.    1018 
 2 Alel~ ESCA~    20 Jul    2020 18:0~  41.5  2.29 C             26.2     29.3     21.9 %             79      84      55 hPa          1017.    1018 
 3 Alel~ ESCA~    20 Jul    2020 18:0~  41.5  2.29 C             23.9     28.1     21.6 %             83      84      57 hPa          1015     1015.
 4 Aren~ ESCA~    20 Jul    2020 18:0~  41.6  2.56 C             25.6     29       20.9 %             81      82      65 hPa          1015.    1016.
 5 Aren~ ESCA~    20 Jul    2020 18:0~  41.6  2.55 C             25.9     27.6     21.2 %             83      84      63 hPa          1016.    1017.
 6 Aren~ ESCA~    20 Jul    2020 18:0~  41.6  2.54 C             25.4     28.2     20.7 %             72      74      48 hPa          1014.    1015.
 7 Arge~ ESCA~    20 Jul    2020 18:0~  41.6  2.39 C             26.2     29.9     20.9 %             76      87      56 hPa          1014.    1014.
 8 Bada~ ESCA~    20 Jul    2020 18:0~  41.5  2.24 C             26.7     28.7     22.4 %             72      80      66 hPa          1017.    1017 
 9 Bada~ ESCA~    20 Jul    2020 18:0~  41.4  2.22 C             28.1     30       22.1 %             66      85      48 hPa          1017.    1018.
10 Bada~ ESCA~    20 Jul    2020 18:0~  41.4  2.22 C             28.8     29.9     22.7 %             61      79      47 hPa          1016.    1017.
# ... with 171 more rows, and 7 more variables: Pres.min <dbl>, Vient.unit <chr>, Vient.act <dbl>, Vient.dir <dbl>, Vient.max <dbl>, Precip.unit <chr>,
#   Precip.total <dbl>
```
