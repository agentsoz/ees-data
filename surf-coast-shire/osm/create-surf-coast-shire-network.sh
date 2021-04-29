#!/bin/bash

###
# Script to generate a new MATSim network for Surf Coast Shire
# Author: Dhirendra Singh, 9/Apr/18
#
# All files are saved relative to the directory of this script.
# Steps:
# 1. Download and install the latest osmosis binary if not already there
# 2. Download and unzip the latest map of Australia (OSM)
# 3. Create a detailed map of the Shire
# 4. Create a larger map of big roads to the major nearby cities
# 5. Combine the two into a final OSM map
# 6. Generate the MATSim network from the above
#
###

### CONFIG ###
OUTFILE_PREFIX=surf_coast_shire
EPSG=EPSG:32754
### END CONFIG ###

DIR=$(dirname "$0")

# download the latest osmosis binary if needed
# https://github.com/openstreetmap/osmosis/releases/download/0.48.3/osmosis-0.48.3.tgz
OSMOSIS_BUILD=0.48.3
OSMOSIS_ZIP=osmosis-latest.tgz
OSMOSIS_DIR=$DIR/osmosis
OSMOSIS_EXE=$DIR/osmosis/bin/osmosis
OSMOSIS_WEB=https://github.com/openstreetmap/osmosis/releases/download/${OSMOSIS_BUILD}/osmosis-${OSMOSIS_BUILD}.tgz
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
  printf "\nInstalled osmosis $OSMOSIS_BUILD in $OSMOSIS_EXE\n\n"
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
# https://raw.githubusercontent.com/JamesChevalier/cities/master/australia/victoria/surf-coast-shire_victoria.poly
polyfile="surf-coast-shire_victoria.poly"
if [ ! -e $DIR/$polyfile ] ; then
  CMD="wget -O $polyfile https://raw.githubusercontent.com/JamesChevalier/cities/master/australia/victoria/$polyfile"
  echo $CMD; eval $CMD
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
# adding primary roads too just for Surf Coast Shire
if [ ! -f $DIR/.bigroads.pbf ] ; then
  printf "\nExtracting larger map of all the big roads to major cities...\n\n"
  $OSMOSIS_EXE --rb file=$DIR/$AU_PBF \
    --bounding-box top=-37.5054 left=143.5611 bottom=-38.8846 right=144.8492 \
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


# Install EES build if needed (from local repo)
EES_BUILD=eeslib-2.1.1-SNAPSHOT
EES_ZIP=${EES_BUILD}-release.zip
EES_DIR=$DIR/ees
EES_WEB=$DIR/../../../ees/ees/target/${EES_ZIP}
if [ ! -d $EES_DIR ] ; then
  cd $DIR
  mkdir $EES_DIR
  cp $EES_WEB $EES_DIR
  cd $EES_DIR
  unzip $EES_ZIP
  printf "\nInstalled EES in $EES_DIR\n\n"
  cd -
fi

# Generate the MATSim network from the final map
printf "\nCreating the final MATSim network...\n\n"
JARS=$(find $EES_DIR -name "*.jar" -print | tr '\r\n' ':')
JARS+=.
CMD="java -cp $JARS io.github.agentsoz.util.NetworkGenerator"
CMD+=" -i $DIR/.merged-network.osm -o $DIR/${OUTFILE_PREFIX}_network.xml -wkt ${EPSG}"
echo $CMD && eval $CMD

# Compress it
gzip -f -9 $DIR/${OUTFILE_PREFIX}_network.xml
printf "\nAll done. New network is in $DIR/${OUTFILE_PREFIX}_network.{xml.gz,osm}\n\n"
