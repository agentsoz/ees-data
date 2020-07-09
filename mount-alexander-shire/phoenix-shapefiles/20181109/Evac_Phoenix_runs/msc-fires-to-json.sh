#!/usr/bin/env bash

dir=$(dirname "$0")

epsg="EPSG:28355" # CRS for Mount Alexander Shire

for file in $dir/*/*_grid.shp; do
        cmd="ogr2ogr -f 'GeoJson' -t_srs $epsg $file.json $file"
        echo $cmd; eval $cmd
done
exit



