

# MPC
library(rstac)
library(terra)

# let's use Korea
kgrid <- vect("vectorfilesdata/kgrid.shp")
# to lon/lat
kgrid <- project(kgrid, "EPSG:4326")
kgridbox <- ext(kgrid)

# let's pull some pollution data
s_obj <- stac("https://planetarycomputer.microsoft.com/api/stac/v1")
it_obj <- s_obj %>%
  stac_search(collections = "sentinel-5p-l2-netcdf",
              bbox = c(kgridbox[1], kgridbox[3], kgridbox[2], kgridbox[4]),
              datetime = "2019-01-01/2019-12-31",
              limit = 1000) %>%
  get_request() %>%
  items_sign(sign_fn = sign_planetary_computer())
# many things!
it_obj
# let's just download the first one
url <- paste0("/vsicurl/", it_obj$features[[1]]$assets$so2$href)
# also get the bounding box for that area
bb <- it_obj$features[[1]]$bbox
# load raster
rall <- rast(url)
# keep just the layer we want and transform to array
rall <- as.array(rall[["aerosol_index_340_380"]])
# now back to raster with the appropriate extent and CRS
rall <- rast(rall, crs = "EPSG:4326", extent = ext(c(bb[1], bb[3], bb[2], bb[4])))

# extract to grids
extractpol <- exact_extract(rall, kgrid, fun = "mean", append_cols = "id")

kgrids <- kgrid |>
  left_join(extractpol |> rename(so2 = mean), by = "id")

# plot it
ggplot() +
  geom_spatvector(data = kgrids, aes(fill = so2), color = NA) +
  scale_fill_distiller("SO2", palette = "Spectral")















# let's pull some land class data
s_obj <- stac("https://planetarycomputer.microsoft.com/api/stac/v1")
it_obj <- s_obj %>%
  stac_search(collections = "io-lulc-annual-v02",
              bbox = c(kgridbox[1], kgridbox[3], kgridbox[2], kgridbox[4]),
              datetime = "2019-01-01/2019-12-31",
              limit = 1000) %>%
  get_request() %>%
  items_sign(sign_fn = sign_planetary_computer())
# fewer things here
it_obj
# let's just download the first one
url <- paste0("/vsicurl/", it_obj$features[[1]]$assets$data$href)
# also get the bounding box for that area
bb <- it_obj$features[[1]]$bbox
# load raster
rall <- rast(url)


plot(rall)













