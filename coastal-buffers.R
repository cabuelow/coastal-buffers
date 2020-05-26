
# libraries
library(sf)
library(tmap)
library(tidyverse)
library(mapedit)
library(leafpm)

# data 
catch <- st_read('Catchments/QLD_Catchments_trans.gpkg')
crop <- st_bbox(c(xmin = 141, xmax = 144, ymax = -10.5, ymin = -13), crs = st_crs(4326))
fnqld <- st_crop(catch, crop) %>% st_transform(crs = 3112)

# unioned coastal buffers
buff <- st_difference(st_union(st_buffer(fnqld, dist =10000)), st_union(fnqld))

