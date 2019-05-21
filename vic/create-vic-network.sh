#!/bin/bash

###
# Script to generate a new MATSim network for all of Victoria
# Author: Dhirendra Singh, 21/May/19
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
OUTFILE_PREFIX=vic
EPSG=EPSG:3111 # used by DELWP, VicGrid94
### END CONFIG ###

DIR=$(dirname "$0")

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

# download the poly files for the region
polyfile="vic.poly"
if [ ! -e $DIR/$polyfile ] ; then
  printf "\nCreating polygon file $DIR/$polyfile...\n\n"
  polys="
  alpine-shire_victoria.poly
  bass-coast-shire_victoria.poly
  shire-of-baw-baw_victoria.poly
  shire-of-buloke_victoria.poly
  shire-of-campaspe_victoria.poly
  shire-of-cardinia_victoria.poly
  shire-of-central-goldfields_victoria.poly
  shire-of-colac-otway_victoria.poly
  shire-of-corangamite_victoria.poly
  shire-of-east-gippsland_victoria.poly
  shire-of-gannawarra_victoria.poly
  shire-of-hepburn_victoria.poly
  shire-of-hindmarsh_victoria.poly
  shire-of-indigo_victoria.poly
  shire-of-loddon_victoria.poly
  shire-of-macedon-ranges_victoria.poly
  shire-of-mansfield_victoria.poly
  shire-of-mitchell_victoria.poly
  shire-of-moira_victoria.poly
  shire-of-moorabool_victoria.poly
  shire-of-mornington-peninsula_victoria.poly
  shire-of-mount-alexander_victoria.poly
  shire-of-moyne_victoria.poly
  shire-of-murrindindi_victoria.poly
  shire-of-nillumbik_victoria.poly
  shire-of-northern-grampians_victoria.poly
  shire-of-pyrenees_victoria.poly
  shire-of-south-gippsland_victoria.poly
  shire-of-strathbogie_victoria.poly
  shire-of-towong_victoria.poly
  shire-of-wellington_victoria.poly
  shire-of-west-wimmera_victoria.poly
  shire-of-yarriambiack_victoria.poly
  surf-coast-shire_victoria.poly
  "
  cd $DIR
  for poly in $polys ; do
    if [ ! -e $poly ] ; then
      CMD="wget -O $poly https://raw.githubusercontent.com/JamesChevalier/cities/master/australia/victoria/$poly"
      echo $CMD; eval $CMD
    fi
  done
  # combine the poly files into a single multi-sectioned file
  $(echo "$polyfile" > $polyfile)
  for poly in $polys ; do
    $(echo "$poly" >> $polyfile)
    $(cat $poly | tail -n +3 | tail -r | tail -n +3 | tail -r >> $polyfile)
    $(echo "END" >> $polyfile)
  done
  $(echo "END" >> $polyfile)
  cd -
  printf "\nWrote polygon into $DIR/$polyfile\n\n"
fi

# Generate a larger map of all the big roads to major cities
if [ ! -f $DIR/.bigroads.pbf ] ; then
  printf "\nExtracting larger map of all the big roads to major cities (takes ~5 mins) ...\n\n"
  $OSMOSIS_EXE --rb file=$DIR/$AU_PBF \
    --bounding-box top=-33.624 left=138.461 bottom=-39.173 right=150.073 \
    completeWays=true --used-node --tf accept-ways \
    highway=motorway,motorway_link,trunk,trunk_link \
    --wb $DIR/.bigroads.pbf
fi

# Generate the detailed map for the Shire and nearby areas
if [ ! -f $DIR/.allroads.pbf ] ; then
  printf "\nExtracting detailed map for area (takes ~2 hrs)...\n\n"
  $OSMOSIS_EXE --rb file=$DIR/$AU_PBF \
    --bounding-polygon file=$DIR/$polyfile \
    completeWays=true --used-node --tf accept-ways \
    highway=motorway,motorway_link,trunk,trunk_link,primary,primary_link,secondary,secondary_link,tertiary,tertiary_link  \
    --wb $DIR/.allroads.pbf
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
UTILREPO=$DIR/../../bdi-abm-integration/util
cp $DIR/.merged-network.osm $UTILREPO
cd $UTILREPO
mvn exec:java -Dexec.mainClass="io.github.agentsoz.util.NetworkGenerator" \
  -Dexec.args="-i .merged-network.osm -o ${OUTFILE_PREFIX}_network.xml -wkt ${EPSG}"
cd -
rm -f $UTILREPO/.merged-network.osm
mv $UTILREPO/${OUTFILE_PREFIX}_network.xml $DIR
gzip -f -9 $DIR/${OUTFILE_PREFIX}_network.xml
printf "\nAll done. New network is in $DIR/${OUTFILE_PREFIX}_network.{xml.gz,osm}\n\n"
