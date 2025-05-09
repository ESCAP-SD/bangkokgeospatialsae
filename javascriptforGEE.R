
# Javascript code
// Load the desired dataset
var dataset = ee.ImageCollection('BNU/FGS/CCNL/v1');

// Set the region to focus on (Korea)
var korea = ee.Geometry.Rectangle([124.5, 33.0, 131.5, 38.5]); // Adjust based on Korea's coordinates

// Define a visualization parameter
var visParams = {
  min: 0,
  max: 100,
  palette: ['blue', 'green', 'yellow', 'red']
};

// Get an image from the dataset
var image = dataset.mean().clip(korea); // You can specify a date if needed

// Add the image to the map
Map.centerObject(korea, 6);  // Center the map on Korea
Map.addLayer(image, visParams, 'BNU/FGS/CCNL/v1');



// Export the image as a GeoTIFF
Export.image.toDrive({
  image: image,
  description: 'BNU_FGS_CCNL_Export',
  scale: 1000, // Define the scale in meters
  region: korea,
  fileFormat: 'GeoTIFF',
  maxPixels: 1e13 // Adjust if needed depending on the size of data
});
