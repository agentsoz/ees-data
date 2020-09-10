# SHP to GeoJson

To create `AireysInlet_grid.shp.json.gz` do:
```
ogr2ogr -f "GeoJSON" -t_srs "EPSG:32754" AireysInlet_grid_epsg32754.shp.json AireysInlet_grid.shp
gzip -9 AireysInlet_grid_epsg32754.shp.json
```
