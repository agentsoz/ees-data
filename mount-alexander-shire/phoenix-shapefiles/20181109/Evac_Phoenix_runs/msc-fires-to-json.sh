#!/usr/bin/env bash

dir=$(dirname "$0")

for epsg in 28355 3857 4326 ; do
        for file in $dir/*/*_grid.shp; do
                cmd="ogr2ogr -f 'GeoJson' -t_srs 'EPSG:$epsg' $file.epsg$epsg.json $file"
                echo $cmd; eval $cmd
        done
done



