
library(sf)
library(tmap)
library(tidyverse)

catch <- st_read('Catchments/QLD_Catchments_trans.gpkg')
fnqld <- st_bbox(c(xmin = 141, xmax = 144, ymax = -10.5, ymin = -13), crs = st_crs(4326))
qld <- st_crop(catch, fnqld) %>% st_transform(crs = 4283)

qld.buff <- st_buffer(qld, dist = 0.1)
qld.buff.dissolve <- st_union(st_buffer(qld, dist = 0.1))
qld.buff.erase <- st_difference(qld.buff.dissolve, st_union(qld))
centroid <- st_centroid(qld)

voronoi <- 
  centroid %>% 
  st_geometry() %>%
  st_union() %>%
  st_voronoi() %>%
  st_collection_extract()

m<-tm_shape(voronoi) +
  tm_polygons(col = 'beige') +
  tm_shape(qld) +
  tm_polygons(col = 'lightblue') +
  tm_shape(qld.buff.erase) +
  tm_polygons() +
  tm_shape(centroid) +
  tm_dots()

tmap_save(m, 'voronoi.png')
