// nighttime lights
var dataset = ee.ImageCollection('NOAA/VIIRS/DNB/ANNUAL_V22')
  .filterDate('2022-01-01', '2022-12-31')
  .select("average_masked"); // Select only the average variable


// Set the region to focus on (Korea)
var korea = ee.Geometry.Rectangle([124.5, 33.0, 131.5, 38.5]); // Adjust based on Korea's coordinates


// Calculate total precipitation for the year by summing the daily values
var image = dataset.first().clip(korea); // just get the first image (only one per year)



// Export the total precipitation raster as a GeoTIFF
Export.image.toDrive({
  image: image,
  description: 'nighttimelights',
  scale: 100, // Define the scale in meters
  region: korea,
  fileFormat: 'GeoTIFF',
  maxPixels: 1e13 // Adjust if needed depending on the size of data
});

