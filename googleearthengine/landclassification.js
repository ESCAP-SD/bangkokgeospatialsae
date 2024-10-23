// Load the desired dataset for total precipitation

var dataset = ee.ImageCollection('COPERNICUS/Landcover/100m/Proba-V-C3/Global')
.filterDate('2019-01-01', '2019-12-31'); // Select only the total precipitation variable


// Set the region to focus on (Korea)
var korea = ee.Geometry.Rectangle([124.5, 33.0, 131.5, 38.5]); // Adjust based on Korea's coordinates


var image = dataset.first().clip(korea); // get first image for the year


// Export the total precipitation raster as a GeoTIFF
Export.image.toDrive({
  image: image,
  description: 'landclass',
  scale: 100, // Define the scale in meters
  region: korea,
  fileFormat: 'GeoTIFF',
  maxPixels: 1e13 // Adjust if needed depending on the size of data
});

