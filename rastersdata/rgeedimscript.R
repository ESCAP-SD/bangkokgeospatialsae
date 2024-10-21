library(tidyverse)
library(sf)
library(terra)
library(tidyterra)
library(rgeedim)

gd_install()
gd_authenticate(auth_mode = "notebook")

gd_initialize()

# Load the shapefile for Malawi
mw3 <- read_sf("day4data/mw4.shp")

# create bounding box
bbox <- st_bbox(mw3)
# let's search for images
x <- "NOAA/VIIRS/DNB/ANNUAL_V21" |>
  gd_collection_from_name() |>
  gd_search(region = bbox)
gd_properties(x)
  
  
  gd_image_from_id() |>
  gd_download(
    filename = "image.tif",
    region = bbox,
    crs = "EPSG:4326", # this is lat/lon
    resampling = "bilinear",
    scale = 500 # The resolution, in meters
  )


