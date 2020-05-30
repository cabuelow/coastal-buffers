# libraries

library(sf)
library(tmap)
library(tidyverse)
library(rmapshaper)

# data 

basin <- st_read('Drainage Basins/drainage-basins.shp') %>% st_transform(crs = 4326)
crop <- st_bbox(c(xmin = 141, xmax = 144, ymax = -10.5, ymin = -13), crs = st_crs(4326))
fnqld <- st_crop(basin, crop) %>% st_transform(crs = 3112)

# remove island basins

fnqld.noisle <- ms_filter_islands(fnqld, min_area = 310468000)

# dissolve basins and buffer

fnqld.dissolve <- st_union(fnqld.noisle)
buff <- st_buffer(fnqld.dissolve, dist = 10000)

# make points along coastline

points <- st_as_sf(fnqld.dissolve %>% st_cast('LINESTRING') %>% 
  st_line_sample(n = 10000))

# create voronoi polygons of coastline points in buffer

voronoi <- st_as_sf(st_intersection(st_cast(st_voronoi(points)), buff) %>% 
                     st_cast('MULTIPOLYGON'))

# intersect voronoi polgyons with basins and dissolve by basin

voronoi.basin <- st_join(voronoi, fnqld.noisle) %>% group_by(BASIN_NAME) %>% summarise()

# mask voronoi basin buffers with land

voronoi.basin.mask <- st_difference(voronoi.basin, fnqld.dissolve)

# union basins with voronoi buffers in a loop
  
# empty spatial dataframe for storing results

nrows <- nrow(fnqld.noisle)
df <- st_sf(BASIN_NAME = 1:nrows, geometry = st_sfc(lapply(1:nrows, function(x) st_polygon())), crs = 3112)
box <- st_bbox(buff)
attr(st_geometry(df), 'bbox') <- box

# loop 

for(i in 1:nrow(fnqld.noisle)) {
  basin <- fnqld.noisle[i,]
  inter <- st_union(basin, filter(voronoi.basin.mask, BASIN_NAME == paste0(as.character(fnqld.noisle[i,]$BASIN_NAME))))
  inter.drop <- ms_filter_islands(inter, min_area = 50000000) %>% dplyr::select(BASIN_NAME, geometry) # drop polygon slivers
  df[i,] <- inter.drop
  df[i,1] <- as.character(inter.drop$BASIN_NAME)
}

# plot

m <- tm_shape(df) +
  tm_polygons('BASIN_NAME') +
  tm_shape(fnqld.noisle) +
  tm_polygons(col = 'white', alpha = 0.5) +
  tm_shape(fnqld.noisle) +
  tm_borders(lwd = 2) +
  tm_layout(legend.show = FALSE, frame = F)

m

#tmap_save(m, 'voronoi.png')
