
# libraries
library(sf)
library(tmap)
library(tidyverse)

# data 
catch <- st_read('Catchments/QLD_Catchments_trans.gpkg')
crop <- st_bbox(c(xmin = 141, xmax = 144, ymax = -10.5, ymin = -13), crs = st_crs(4326))
fnqld <- st_crop(catch, crop) %>% st_transform(crs = 3112)

# unioned coastal buffers
buff <- st_difference(st_union(st_buffer(fnqld, dist =10000)), st_union(fnqld))

# catchment centroids
centroid <- st_centroid(fnqld)

# catchment voronoi polygons
voronoi <- 
  centroid %>% st_geometry() %>%
  st_union() %>% st_voronoi() %>%
  st_collection_extract()

# plot
m <- tm_shape(voronoi) +
  tm_polygons(col = 'beige') +
  tm_shape(buff) +
  tm_polygons() +
  tm_shape(fnqld) +
  tm_polygons(col = 'lightblue') +
  tm_shape(centroid) +
  tm_dots()

m

#tmap_save(m, 'voronoi.png')
