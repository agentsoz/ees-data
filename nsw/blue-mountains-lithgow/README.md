# Blue Mountains / Lithgow - Scenario Data

## Address Points

The file `blue-mountains-lithgow-addresses.csv` contains valid attresses for the [City of Blue Mountains](https://en.wikipedia.org/wiki/City_of_Blue_Mountains) and [City of Lithgow](https://en.wikipedia.org/wiki/City_of_Lithgow) and was created as follows:
- Export the [NSW Geocoded Addressing Theme - Address Point](https://portal.spatial.nsw.gov.au/portal/home/item.html?id=d3cf7c7edef14ca18248c6dc5fcaff96) data for the above LGAs separately in ESRI Shapefile format.
- Load the Shapefiles in QGIS and [merge](https://qgis3-10-geoanalysis-un.readthedocs.io/en/latest/vector/merge.html) into a single layer.
- Edit the Attribute Table, to first remove all rows where `"housenumbe" IS NULL`, and then remove all columns but `address`.
- Export layer as CSV using `CRS EPSG:7855 - GDA2020 / MGA zone 55` and ensuring `GEOMETRY` is set to `AS_XY`.
