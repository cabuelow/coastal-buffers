# coastal-buffers

Create coastal buffers of catchment polygons that only extend seaward. Buffer boundaries must align with catchment polygon boundaries.

Load libraries

``` r
library(sf)
```

    ## Linking to GEOS 3.7.2, GDAL 2.4.2, PROJ 5.2.0

``` r
library(tmap)
library(tidyverse)
```

    ## ── Attaching packages ─────────────────────────────────────────────── tidyverse 1.3.0 ──

    ## ✓ ggplot2 3.2.1     ✓ purrr   0.3.3
    ## ✓ tibble  2.1.3     ✓ dplyr   0.8.4
    ## ✓ tidyr   1.0.2     ✓ stringr 1.4.0
    ## ✓ readr   1.3.1     ✓ forcats 0.4.0

    ## ── Conflicts ────────────────────────────────────────────────── tidyverse_conflicts() ──
    ## x dplyr::filter() masks stats::filter()
    ## x dplyr::lag()    masks stats::lag()

Import spatial data, crop and project

``` r
catch <- st_read('Catchments/QLD_Catchments_trans.gpkg')
```

    ## Reading layer `QLD_Catchments_trans' from data source `/Users/christinabuelow/Dropbox/coastal-buffers/Catchments/QLD_Catchments_trans.gpkg' using driver `GPKG'
    ## Simple feature collection with 187 features and 27 fields
    ## geometry type:  MULTIPOLYGON
    ## dimension:      XY
    ## bbox:           xmin: 137.9947 ymin: -29.17927 xmax: 153.5518 ymax: -10.68753
    ## epsg (SRID):    4326
    ## proj4string:    +proj=longlat +datum=WGS84 +no_defs

``` r
crop <- st_bbox(c(xmin = 141, xmax = 144, ymax = -10.5, ymin = -13), crs = st_crs(4326))
fnqld <- st_crop(catch, crop) %>% st_transform(crs = 3112)
```

    ## although coordinates are longitude/latitude, st_intersection assumes that they are planar

    ## Warning: attribute variables are assumed to be spatially constant
    ## throughout all geometries

Generate unioned coastal buffers

``` r
buff <- st_difference(st_union(st_buffer(fnqld, dist =10000)), st_union(fnqld))
```

Get catchment polygon centroids

``` r
centroid <- st_centroid(fnqld)
```

    ## Warning in st_centroid.sf(fnqld): st_centroid assumes attributes are
    ## constant over geometries of x

Generate catchment voronoi polygons

``` r
voronoi <- 
  centroid %>% 
  st_geometry() %>%
  st_union() %>%
  st_voronoi() %>%
  st_collection_extract()
```

Map 

``` r
tm_shape(voronoi) +
  tm_polygons(col = 'beige') +
  tm_shape(buff) +
  tm_polygons() +
  tm_shape(fnqld) +
  tm_polygons(col = 'lightblue') +
  tm_shape(centroid) +
  tm_dots()
```
