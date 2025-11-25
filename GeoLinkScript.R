# ============================================================================
# LAGOS GEOSPATIAL FEATURE EXTRACTION SCRIPT
# Purpose: Extract and compile geospatial features for Lagos state grid cells
# Output: Features dataset with population, infrastructure, and environmental indicators
# ============================================================================

# 1. SETUP AND INITIALIZATION -----------------------------------------------
# Set working directory and clear environment
setwd("C:/Users/wb610463/OneDrive - WBG/Documents/BangkokSAE")
rm(list=ls())  # Clear all objects from workspace

# Load required libraries
library(devtools)    # For installing packages from GitHub
library(tidyverse)   # For data manipulation
library(sf)          # For spatial data processing

# Install GeoLink package from GitHub (or local backup)
# Uncomment below for GitHub installation:
devtools::install_github("SSA-Statistical-Team-Projects/GeoLink", force = TRUE)

# Local install as a backup option:
# install.packages("C:/Users/wb200957/OneDrive - WBG/DEC/Github projects/GeoLink", repos = NULL, type = "source")
library(GeoLink) 

# 2. LOAD AND PREPARE STUDY AREA --------------------------------------------
# Load Nigeria administrative boundary shapefile (included with GeoLink package)
data(shp_dt)

# Filter to Lagos state only
shp_dt <- shp_dt[shp_dt$ADM1_EN == "Lagos",]

# Transform to Albers Equal Area Conic projection (EPSG:5070) for accurate area calculations
shp_dt <- st_transform(shp_dt, 5070)

# Generate 1km x 1km grid cells covering Lagos state
grid <- gengrid2(
  shp_dt = shp_dt,
  grid_size = 1000,  # Grid size in meters (1km)
  sqr = TRUE          # Square grid cells (vs hexagonal)
)

# 3. POPULATION DATA --------------------------------------------------------
# Extract WorldPop population estimates for each grid cell
# Using 2025 population raster at 1km resolution
population_grid <- GeoLink:::process_raster(
  shp_dt = grid,
  raster_file = "./nga_pop_2025_CN_1km_R2025A_UA_v1.tif",
  extract_fun = "sum",  # Sum population within each grid cell
  grid_size = NULL
)

# Rename extracted feature column for clarity
population_grid <- population_grid |>
  rename(population = geolink_feature)

# Remove unpopulated grid cells (population = 0) to reduce processing
grid <- grid[population_grid$population > 0,]
population_grid <- population_grid[population_grid$population > 0,]

# Save filtered grid for future use
saveRDS(grid, file = "grid")
grid <- readRDS("grid")

# 4. NIGHTTIME LIGHTS -------------------------------------------------------
# Extract mean nighttime light intensity for 2022
# Indicates economic activity and infrastructure development
ntl_grid <- geolink_ntl(
  username = "davidn10",           # NASA Earthdata username
  password = "Logmeon123456!",     # NASA Earthdata password
  time_unit = "annual",            # Annual aggregation
  start_date = "2022-01-01",
  end_date = "2022-12-31",
  shp_dt = grid
)

# 5. BUILDING FOOTPRINTS ----------------------------------------------------
# Extract WorldPop building density data
# Provides information on built environment and urbanization
geolink_buildings_grid <- geolink_buildings(
  iso_code = "NGA",      # Nigeria ISO code
  version = "v1.1",      # Dataset version
  shp_dt = grid
) 

# 6. VEGETATION INDEX (NDVI) -----------------------------------------------
# Extract Normalized Difference Vegetation Index
# Measures vegetation health and greenness
geolink_ndvi_grid <- geolink_vegindex(
  shp_dt = grid,
  start_date = "2022-01-01",
  end_date = "2022-12-31"
) 

# Calculate annual mean NDVI from monthly values
geolink_ndvi_grid <- st_drop_geometry(geolink_ndvi_grid)  # Remove geometry for processing

indices <- grepl(pattern = "^ndvi_y2022_m*", x = colnames(geolink_ndvi_grid))  # Find monthly columns

geolink_ndvi_grid[, indices][is.na(geolink_ndvi_grid[, indices])] <- 0 # Convert NaNs to 0s

geolink_ndvi_grid[,"ndvi_y2022"] <- rowMeans(geolink_ndvi_grid[, indices])  # Calculate mean

geolink_ndvi_grid <- geolink_ndvi_grid[, !indices]  # Remove monthly columns, keep annual mean

# 7. AIR POLLUTION (OZONE) -------------------------------------------------
# Extract ozone (O3) pollution levels
geolink_pollution_o3_grid <- geolink_pollution(
  start_date = "2022-01-01",
  end_date = "2022-12-31", 
  indicator = "o3",      # Ozone indicator
  shp_dt = grid
) 

# Calculate annual mean ozone from monthly values
geolink_pollution_o3_grid$o3_y2022_m6 <- NULL  # Remove problematic June column if exists
geolink_pollution_o3_grid <- st_drop_geometry(geolink_pollution_o3_grid)
indices <- grepl(pattern = "^o3_y2022_m*", x = colnames(geolink_pollution_o3_grid)) 
geolink_pollution_o3_grid[,"o3_y2022"] <- rowMeans(geolink_pollution_o3_grid[, indices])
geolink_pollution_o3_grid <- geolink_pollution_o3_grid[, !indices]

# 8. CELLULAR INFRASTRUCTURE -----------------------------------------------
# Process OpenCellID data for cellular tower locations
# File 621.csv.gz contains Nigeria cell tower data
geolink_cell_grid <- geolink_opencellid(
  cell_tower_file = "./621.csv.gz",  # Nigeria OpenCellID file
  shp_dt = grid
) 

# Calculate distance to nearest cell tower for each grid cell
# Indicates connectivity and infrastructure access
geolink_cell_grid <- st_as_sf(cbind(geolink_cell_grid, grid$geometry))  # Add geometry back
cell_towers <- st_as_sf(geolink_cell_grid[geolink_cell_grid$cell_towers > 0,])  # Get cells with towers
nearest_indices <- st_nearest_feature(geolink_cell_grid, cell_towers)  # Find nearest tower
geolink_cell_grid$distance_nearest_tower <- st_distance(
  geolink_cell_grid, 
  cell_towers[nearest_indices, ], 
  by_element = TRUE
)

# 9. LAND COVER CLASSIFICATION ----------------------------------------------
# Extract land cover types for each grid cell
# Provides information on land use patterns
geolink_land_grid <- geolink_landcover(
  shp_dt = grid,
  start_date = "2022-01-01",
  end_date = "2022-12-31"
) 

# 11. DATA COMPILATION ------------------------------------------------------
# Combine all feature datasets into single dataframe

# Create list of all feature datasets
data <- list(population_grid, ntl_grid, geolink_ndvi_grid, 
             geolink_cell_grid, geolink_land_grid)

# Remove geometry from all datasets except population_grid
for (x in data[data != "population_grid"]) {
  x <- st_drop_geometry(x)
}

# Select relevant columns from each dataset
population_grid <- select(population_grid, c("poly_id", "ADM2_EN", "ADM2_PCODE", "population"))
ntl_grid <- select(ntl_grid, "ntl_mean") 
geolink_ndvi_grid <- select(geolink_ndvi_grid, "ndvi_y2022")
geolink_cell_gid <- select(geolink_cell_grid, c("cell_towers", "distance_nearest_tower"))
geolink_land_grid <- select(geolink_land_grid, "water":"rangeland")  # Select all land cover columns

# Combine all datasets column-wise
features <- do.call(cbind, data)

# Clean up duplicate columns created by cbind
# Remove columns with .1, .2, .3, etc. suffixes
features <- features[, !grepl("\\.[0-9]+$", names(features))]

# Remove any unwanted V2 column if it exists
features$V2 <- NULL

# Save final features dataset
saveRDS(features, file = "features")