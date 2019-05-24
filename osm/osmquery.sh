#!/usr/bin/env bash

if [ $# -ne 1 ];
    then echo "usage $0 FILE.query"
    exit
fi
CMD="wget -O $1.result.csv --post-file=$1 'http://overpass-api.de/api/interpreter'"
echo $CMD; eval $CMD
