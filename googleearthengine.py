"""
- This script shows how to pull some simple rasters from GEE
- First, you need to create a venv in the terminal
python3 -m venv geeexample
source geeexample/bin/activate
- Now, you need to install packages, specifically ee (upgrade is just in case you already have it)
pip3 install earthengine-api --upgrade
"""
# import ee
import ee
# authenticate. this will open a pop up
ee.Authenticate(force=True)

"""
Then we need to initialize the project.
To do this, we need to do two things:
1. Create a GEE account.
2. Create a "project" in the account. This is in the terminal:
instructions here: https://developers.google.com/earth-engine/guides/transition_to_cloud_projects
"""
# the project name is from the authenticate bit
ee.Initialize(project="ee-geefolder")


# let's start with landcover
lc = ee.ImageCollection("MODIS/006/MCD12Q1")

# what dates do we want?
initial = "2017-01-01"
final = "2017-12-31"

# now filter
lc = lc.filterDate(initial, final)






