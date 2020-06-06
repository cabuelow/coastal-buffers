# libraries

library(sf)
library(tmap)
library(tidyverse)
library(rmapshaper)

# data

basin <- st_read('Drainage Basins/drainage-basins.shp') %>% st_transform(crs = 3112)

# remove island basins

basin.noisle <- ms_filter_islands(basin, min_area = 10000000000)

# dissolve basins and buffer

basin.dissolve <- st_union(basin.noisle)
buff <- st_buffer(basin.dissolve, dist = 10000)
rev.buff <- st_buffer(basin.dissolve, dist = -10000)
thin.buff <- st_difference(buff, rev.buff)

# make points along coastline

points <- st_as_sf(basin.dissolve %>% st_cast('POLYGON') %>% st_cast('LINESTRING') %>% 
                     st_line_sample(n = 5000)) %>% st_difference()

# create voronoi polygons of coastline points in buffer

voronoi <- st_as_sf(st_intersection(st_cast(st_voronoi(points)), thin.buff) %>% 
                      st_cast('MULTIPOLYGON'))

# intersect voronoi polgyons with coastal basin areas and dissolve by basin

voronoi.basin <- st_join(voronoi, st_difference(basin.noisle, st_buffer(basin.dissolve, -1000))) %>% 
  group_by(BASIN_NAME) %>% summarise()

# mask voronoi basin buffers with land

voronoi.basin.mask <- st_difference(voronoi.basin, basin.dissolve)

# union basins with voronoi buffers in a loop

# empty spatial dataframe for storing results

nrows <- nrow(basin.noisle)
df <- st_sf(BASIN_NAME = 1:nrows, geometry = st_sfc(lapply(1:nrows, function(x) st_polygon())), crs = 3112)
box <- st_bbox(buff)
attr(st_geometry(df), 'bbox') <- box

# loop 

for(i in 1:nrow(basin.noisle)) {
  basin <- basin.noisle[i,]
  inter <- st_union(basin, filter(voronoi.basin.mask, BASIN_NAME == paste0(as.character(basin.noisle[i,]$BASIN_NAME))))
  inter.drop <- inter %>% dplyr::select(BASIN_NAME, geometry)
  df[i,] <- inter.drop
  df[i,1] <- as.character(inter.drop$BASIN_NAME)
}

# cast as spatial dataframe

df <- st_cast(df, 'MULTIPOLYGON') %>% group_by(BASIN_NAME) %>% summarise()

# write spatial dataframe as geopackage

st_write(df, 'basins-buffer-qld.gpkg', overwrite=T, append= F)

# plot

m <- tm_shape(df) +
  tm_polygons('BASIN_NAME') +
  tm_shape(basin.noisle) +
  tm_polygons(col = 'white', alpha = 0.5) +
  tm_shape(basin.noisle) +
  tm_borders(lwd = 2) +
  tm_layout(legend.show = FALSE, frame = F)

m

#tmap_save(m, 'voronoi.png')
