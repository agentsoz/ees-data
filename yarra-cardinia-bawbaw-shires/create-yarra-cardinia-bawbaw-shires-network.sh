#!/bin/bash

###
# Script to generate a new MATSim network for a  region
# Author: Dhirendra Singh
#
# All files are saved relative to the directory of this script.
# Steps:
# 1. Download and install the latest osmosis binary if not already there
# 2. Download and unzip the latest map of Australia (OSM)
# 3. Create a detailed map of the new region
# 4. Create a larger map of big roads to the major nearby cities
# 5. Combine the two into a final OSM map
# 6. Generate the MATSim network from the above
#
###

DIR=$(dirname "$0")

### CONFIG ###
EESDIR=$DIR/../../ees
OUTFILE_PREFIX=yarra_cardinia_bawbaw_shires
EPSG=EPSG:32755
POLY_FILE="yarra_cardinia_bawbaw_shires_victoria.poly"
BOUNDING_BOX="top=-35.057 left=145.190 bottom=-39.034 right=150.584"
### END CONFIG ###


# download the latest osmosis binary if needed
OSMOSIS_ZIP=osmosis-latest.tgz
OSMOSIS_DIR=$DIR/osmosis
OSMOSIS_EXE=$DIR/osmosis/bin/osmosis
OSMOSIS_WEB=https://bretth.dev.openstreetmap.org/osmosis-build/${OSMOSIS_ZIP}
if [ ! -d $OSMOSIS_DIR ] ; then
  cd $DIR
  printf "\nGetting $OSMOSIS_WEB ...\n\n"
  wget -O $OSMOSIS_ZIP $OSMOSIS_WEB
  mkdir $OSMOSIS_DIR
  mv $OSMOSIS_ZIP $OSMOSIS_DIR
  cd $OSMOSIS_DIR
  tar xvfz $OSMOSIS_ZIP
  rm -f OSMOSIS_ZIP
  chmod a+x bin/osmosis
  printf "\nInstalled latest osmosis in $OSMOSIS_EXE\n\n"
  cd -
fi

# download the latest OSM extract for Australia if needed from:
# http://download.gisgraphy.com/openstreetmap/pbf/AU.tar.bz2
AU_PBF=AU.pbf
OSM_ZIP=AU.tar.bz2
OSM_WEB=http://download.gisgraphy.com/openstreetmap/pbf/$OSM_ZIP
if [ ! -f $DIR/$AU_PBF ] ; then
  cd $DIR
  printf "\nGetting $OSM_WEB ...\n\n"
  wget -O $OSM_ZIP http://download.gisgraphy.com/openstreetmap/pbf/$OSM_ZIP
  printf "\nExtracting PBF from archive...\n\n"
  tar -jxvf $DIR/$OSM_ZIP
  mv AU $AU_PBF
  cd -
fi

# download the poly file for the Shire
# https://github.com/JamesChevalier/cities/tree/master/australia/victoria
# NOTE: if not found there try using an OSM relation id with:
# curl -o my.poly -d 'id=3333996&params=0' http://polygons.openstreetmap.fr/get_poly.py
polyfile=$POLY_FILE
if [ ! -e $DIR/$polyfile ] ; then
  # Yarra Ranges Shire: osm relation id 3333996
  # Cardinia Shire: osm relation id 3335652
  # Baw Baw Shire: osm relation id 3335695
  polys="3333996 3335652 3335695"
  # get the poly files
  for poly in $polys ; do
    CMD="curl -o $DIR/${poly}.poly -d 'id=${poly}&params=0' http://polygons.openstreetmap.fr/get_poly.py"
    echo $CMD; eval $CMD
  done
  # combine the poly files
  $(echo "$polyfile" > $polyfile)
  for poly in $polys ; do
    $(echo "$poly" >> $polyfile)
    $(cat $DIR/${poly}.poly | tail -n +3 | tail -r | tail -n +3 | tail -r >> $polyfile)
    $(echo "END" >> $polyfile)
  done
  $(echo "END" >> $polyfile)
  printf "\nWrote poly file into $DIR/$polyfile\n\n"
  for poly in $polys ; do
    rm -f $DIR/${poly}.poly
  done
fi

# Generate the detailed map for the Shire and nearby areas
if [ ! -f $DIR/.allroads.pbf ] ; then
  printf "\nExtracting detailed map for area...\n\n"
  $OSMOSIS_EXE --rb file=$DIR/$AU_PBF \
    --bounding-polygon file=$DIR/$polyfile \
    completeWays=true --used-node --tf accept-ways \
    highway=motorway,motorway_link,trunk,trunk_link,primary,primary_link,secondary,secondary_link,tertiary,tertiary_link,residential,unclassified  \
    --wb $DIR/.allroads.pbf
fi

# Generate a larger map of all the big roads to major cities
if [ ! -f $DIR/.bigroads.pbf ] ; then
  printf "\nExtracting larger map of all the big roads to major cities...\n\n"
  $OSMOSIS_EXE --rb file=$DIR/$AU_PBF \
    --bounding-box $BOUNDING_BOX \
    completeWays=true --used-node --tf accept-ways \
    highway=motorway,motorway_link,trunk,trunk_link,primary,primary_link \
    --wb $DIR/.bigroads.pbf
fi

# Merge the two into a final map
if [ ! -f $DIR/.merged-network.osm ] ; then
printf "\nMerging the two into a final map...\n\n"
$OSMOSIS_EXE --rb file=$DIR/.allroads.pbf --rb file=$DIR/.bigroads.pbf --merge \
  --wx $DIR/.merged-network.osm
  cp $DIR/.merged-network.osm $DIR/${OUTFILE_PREFIX}_network.osm

fi

# Generate the MATSim network from the final map
printf "\nCreating the final MATSim network...\n\n"
cp $DIR/.merged-network.osm $EESDIR
cd $EESDIR
mvn exec:java -Dexec.mainClass="io.github.agentsoz.util.NetworkGenerator" \
  -Dexec.args="-i .merged-network.osm -o ${OUTFILE_PREFIX}_network.xml -wkt ${EPSG}"
cd -
rm -f $EESDIR/.merged-network.osm
mv $EESDIR/${OUTFILE_PREFIX}_network.xml $DIR
gzip -f -9 $DIR/${OUTFILE_PREFIX}_network.xml
printf "\nAll done. New network is in $DIR/${OUTFILE_PREFIX}_network.{xml.gz,osm}\n\n"
