#!/usr/bin/env bash
OSM2GEO=osmtogeojson
command -v $OSM2GEO >/dev/null 2>&1 || { echo >&2 "Install $OSM2GEO first: npm install -g osmtogeojson"; exit 1; }

if [ $# -ne 1 ];
    then echo "usage $0 FILE.query"
    exit
fi
CMD="wget -O .osm --post-file=$1 'http://overpass-api.de/api/interpreter'"
echo $CMD; eval $CMD
CMD="$OSM2GEO .osm > $1.result.json; rm .osm"
echo $CMD; eval $CMD
