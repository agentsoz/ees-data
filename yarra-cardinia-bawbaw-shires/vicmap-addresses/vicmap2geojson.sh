#!/usr/bin/env bash

DIR=$(dirname "$0")
ZIPFILE=$DIR/SDM644524.zip
OUTCSV=$DIR/yarra-cardinia-bawbaw-addresses.csv
NAMES=("baw baw" "cardinia" "yarra ranges")

TMPDIR=$DIR/tmp
if [ ! -d $TMPDIR ] ; then
  CMD="mkdir -p $TMPDIR"; echo $CMD; eval $CMD
  CMD="unzip -o -d $TMPDIR $ZIPFILE"; echo $CMD; eval $CMD
fi

# create the output csv with the attribute headers
CMD="printf \"LGA_CODE|POSTCODE|LOCALITY|EZI_ADD|MESH_BLOCK|COORDINATES\n\" > $OUTCSV"; echo $CMD; eval $CMD

# python3 script for extracting the relevant geojson attributes into a csv
read -r -d '' PYSCRIPT << EOM
import sys,json;

data=json.load(sys.stdin);

for feature in data['features']:
    print(feature['properties']['LGA_CODE'], '|', feature['properties']['POSTCODE'], '|', feature['properties']['LOCALITY'], '|', feature['properties']['EZI_ADD'], '|', feature['properties']['MESH_BLOCK'], '|', feature['geometry']['coordinates'], sep='');
EOM

# write out the csv rows
for name in "${NAMES[@]}"; do
  file=$TMPDIR/vicgrid94/shape/lga_polygon/${name}-1000/VMADD/ADDRESS.shp
  outname=$TMPDIR/vicmap-addresses-${name// /-}.geojson
  if [ ! -e $outname ] ; then
    CMD="ogr2ogr -f GeoJSON -t_srs \"EPSG:4326\" $outname \"$file\""
    echo $CMD; eval $CMD
  fi
  CMD="cat $outname | python3 -c \"$PYSCRIPT\" >> $OUTCSV"
  echo $CMD; eval "$CMD"
done

# compress it
CMD="gzip -9 $OUTCSV"; echo $CMD; eval "$CMD"
