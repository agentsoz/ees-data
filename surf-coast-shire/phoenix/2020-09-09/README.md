# SHP to GeoJson

To create `AireysInlet_grid.shp.json.gz` do:
```
ogr2ogr -f "GeoJSON" -t_srs "EPSG:3111" AireysInlet_grid.shp.json AireysInlet_grid.shp
gzip -9 AireysInlet_grid.shp.json
```
