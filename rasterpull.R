# rgeedim and mpc examples

library(rgeedim)
# Might say "do you want to create a default python environment for the reticulate pacakge?"
# say yes
# 1. restart R
# 2. tools --> global options --> python --> select --> virtual environments --> r-reticulate
# make sure to select the python3.XX option!


# use "conda" environment named "RGEEDIM" to set up rgeedim
gd_install(envname = "RGEEDIM")
# make sure tos et up interpreter correctly
# 1. restart R
# 2. tools --> global options --> python --> select --> conda environments --> RGEEDIM





library(reticulate)
# copy-paste this from 2. above
Sys.setenv("RETICULATE_PYTHON" = "~/Library/r-miniconda-arm64/envs/RGEEDIM/bin/python3.9")
library(rgeedim)
library(tidyverse)
library(terra)
library(tidyterra)
library(exactextractr)
library(sf)
library(cowplot)

# Need a google account!

# short duration token
gd_authenticate(auth_mode = "notebook")
# initialize and should be good to go 
gd_initialize()


# we want to pull data for a specific region!
# let's use Korea
kgrid <- read_sf("vectorfilesdata/kgrid.shp")
# to lon/lat
kgrid <- st_transform(kgrid, "EPSG:4326")
kgridbox <- st_bbox(kgrid)



# Let's take a look at nighttime lights
# find more information on the GEE website. Just search for NOAA/VIIRS/DNB/MONTHLY_V1/VCMCFG in google
# this is monthly, let's look at two years of data
x <- "NOAA/VIIRS/DNB/MONTHLY_V1/VCMCFG" |>
  gd_collection_from_name() |> # COLLECTION, because there are many images
  # we are going to SEARCH, not download
  gd_search(
    start_date = "2022-01-01",
    end_date = "2024-10-31",
    region = kgridbox,
    crs = "EPSG:4326", # lat/lon
    scale = 500
  )
# list the names and timing.
# we can create a list of image ids and the associated dates
imageresults <- gd_properties(x)
imageresults
# turn date variable into a date variable
imageresults$date <- as_date(imageresults$date)
head(imageresults)

# let's download the first image!
raster <- imageresults$id[1] |>
  gd_image_from_id() |>
  gd_download(
    filename = "ntl.tif",
    region = kgridbox,
    scale = 500,
    crs = 'EPSG:4326',
    dtype = 'uint16',
    overwrite = TRUE, # overwrite if it exists
    silent = FALSE
  )

# let's take a look at the raster
ntl <- rast(raster)
plot(ntl$avg_rad)

# extract to grids!
extractntl <- exact_extract(ntl, kgrid, fun = "mean", append_cols = "id")
# what does it look like?
head(extractntl)

# add to grids
kgrid <- kgrid |>
  left_join(extractntl, by = "id")

# plot it
ggplot() +
  geom_spatvector(data = kgrid, aes(fill = log(mean.avg_rad)), color = NA) +
  scale_fill_distiller("Nightlights", palette = "Spectral")




# make sure to check the DATES!
x <- "COPERNICUS/Landcover/100m/Proba-V-C3/Global" |>
  gd_collection_from_name() |> # COLLECTION, because there are many images
  # we are going to SEARCH, not download
  gd_search(
    start_date = "2015-01-01",
    end_date = "2020-01-01",
    region = kgridbox,
    crs = "EPSG:4326", # lat/lon
    scale = 500
  )
imageresults <- gd_properties(x)
imageresults
# turn date variable into a date variable
imageresults$date <- as_date(imageresults$date)
head(imageresults)

# let's download the LAST image
raster <- imageresults$id[length(imageresults$id)] |>
  gd_image_from_id() |>
  gd_download(
    filename = "lc.tif",
    region = kgridbox,
    scale = 500,
    crs = 'EPSG:4326',
    dtype = 'uint16',
    overwrite = TRUE, # overwrite if it exists
    silent = FALSE
  )
lc <- rast(raster)
# check names
names(lc)
# we are going to use the "coverfraction" variables
lc <- lc[[c("bare-coverfraction", "urban-coverfraction", "crops-coverfraction",
  "grass-coverfraction", "shrub-coverfraction", "tree-coverfraction")]]

lc <- exact_extract(lc, kgrid, fun = "mean", append_cols = "id")

# add to grids
kgrid <- kgrid |>
  left_join(lc, by = "id")


# plot urban
ggplot() +
  geom_spatvector(data = kgrid, aes(fill = `mean.urban-coverfraction`), color = NA) +
  scale_fill_distiller("Urban\npct.", palette = "Spectral")
# plot crops
ggplot() +
  geom_spatvector(data = kgrid, aes(fill = `mean.crops-coverfraction`), color = NA) +
  scale_fill_distiller("Crops\npct.", palette = "Spectral")

# plot both!
g1 <- ggplot() +
  geom_spatvector(data = kgrid, aes(fill = `mean.urban-coverfraction`), color = NA) +
  scale_fill_distiller("Urban\npct.", palette = "Spectral")
g2 <- ggplot() +
  geom_spatvector(data = kgrid, aes(fill = `mean.crops-coverfraction`), color = NA) +
  scale_fill_distiller("Crops\npct.", palette = "Spectral")
plot_grid(g1, g2)




# MPC
library(rstac)


# let's pull some pollution data
s_obj <- stac("https://planetarycomputer.microsoft.com/api/stac/v1")
it_obj <- s_obj %>%
  stac_search(collections = "sentinel-5p-l2-netcdf",
              bbox = kgridbox,
              datetime = "2019-01-01/2019-12-31",
              limit = 1000) %>%
  get_request() %>%
  items_sign(sign_fn = sign_planetary_computer())
# many things!
it_obj
# let's just download the first one
url <- paste0("/vsicurl/", it_obj$features[[1]]$assets$so2$href)
# also get the bounding box for that area
bbox <- list(it_obj$features[[1]]$bbox)
# load raster
rall <- rast(url)
# keep just the layer we want and transform to array
rall <- as.array(rall[["aerosol_index_340_380"]])
# now back to raster with the appropriate extent and CRS
rall <- rast(rall, crs = "EPSG:4326", extent = ext(c(bbox[[1]][1], bbox[[1]][3], bbox[[1]][2], bbox[[1]][4])))

# extract to grids
extractpol <- exact_extract(rall, kgrid, fun = "mean", append_cols = "id")

kgrids <- kgrid |>
  left_join(extractpol |> rename(so2 = mean), by = "id")

# plot it
ggplot() +
  geom_spatvector(data = kgrids, aes(fill = so2), color = NA) +
  scale_fill_distiller("SO2", palette = "Spectral")


