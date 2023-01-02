#!/bin/bash

#Author: Supun Jayathilake (supunj@gmail.com)

function merge_all()
{
	#Copy other pre-compiled maps
	echo 'Copying pre-compiled maps...'
	cp $OTHER_IMG_LOC/*.img $IMG_LOC
	echo 'Copying pre-compiled maps...done'

	#Combine all img files into one
	IMG_STRING=''
	for file in `find $IMG_LOC -maxdepth 1 -type f -name "*.img" -o -name "*.mdx"`
	do
		IMG_STRING="$IMG_STRING $file"
	done

	cd $IMG_LOC/mapset
	echo "Combining all maps...."
	echo $MKGMAP_JAVACMD $MKGMAP_JAVACMD_OPTIONS -jar $MKGMAP --code-page=1252 --keep-going --gmapsupp --tdbfile --index $IMG_STRING $TYP_FILE
	$MKGMAP_JAVACMD $MKGMAP_JAVACMD_OPTIONS -jar $MKGMAP --code-page=1252 --keep-going --gmapsupp --tdbfile --index $IMG_STRING $TYP_FILE
	echo 'Combining done.'
}

function prepare()
{
	# Content locations
	MAP_ROOT=$(dirname $(readlink -f $0))
	TEMP_LOC=$MAP_ROOT/tmp
	OSM_LOC=$MAP_ROOT/maps/osm
	IMG_LOC=$TEMP_LOC/Garmin
	OTHER_IMG_LOC=$MAP_ROOT/maps/img
	PBF_LOC=$MAP_ROOT/maps/pbf
	GPI_LOC=$TEMP_LOC/gpi
	ARG_LOC=$MAP_ROOT/arg
	SPLIT_LOC=$MAP_ROOT/tmp/split
	STYLE_LOC=$MAP_ROOT/style
	ICON_LOC=$MAP_ROOT/icon
	TYP_LOC=$MAP_ROOT/typ
	
	# Tools
	MKGMAP=$MAP_ROOT/tools/mkgmap-r4594/mkgmap.jar
	OSMOSIS_LOC=$MAP_ROOT/tools/osmosis-0.48.3
	OSMOSIS=$OSMOSIS_LOC/bin/osmosis
	SPLITTER=$MAP_ROOT/tools/splitter-r597/splitter.jar
	# Files
	SOURCE_MAP_PBF=$PBF_LOC/sri-lanka-latest.osm.pbf

	export MKGMAP_JAVACMD=/usr/bin/java
	export MKGMAP_JAVACMD_OPTIONS="-Xmx4096M -jar -enableassertions"

	rm -rf $TEMP_LOC
	mkdir -p $TEMP_LOC/poi
	mkdir -p $TEMP_LOC/typ
  	mkdir -p $GPI_LOC
	mkdir -p $IMG_LOC/mapset
	mkdir -p $SPLIT_LOC
	
	# Copy map
	cp $SOURCE_MAP_PBF $TEMP_LOC/sri-lanka-latest.osm.pbf
	
	echo 'Splitting....'
	cd $SPLIT_LOC
	$MKGMAP_JAVACMD $MKGMAP_JAVACMD_OPTIONS $SPLITTER $TEMP_LOC/sri-lanka-latest.osm.pbf
	echo 'Splitting done.'
	cd $MAP_ROOT

	cat $TYP_LOC/os50mod/header.txt $TYP_LOC/os50mod/polygon.txt $TYP_LOC/os50mod/line.txt $TYP_LOC/os50mod/poi.txt > $TEMP_LOC/typ/os50mod.txt
	TYP_FILE=$TEMP_LOC/typ/os50mod.txt
}

# ------------- Start -------------
prepare

# Start building maps
cd $IMG_LOC

echo 'Generating transport map....'
IMG_FILE_NAME="`shuf -i 10000000-99999999 -n 1`"
$MKGMAP_JAVACMD $MKGMAP_JAVACMD_OPTIONS $MKGMAP -c $ARG_LOC/transport_osm.args --description=Transport --mapname=$IMG_FILE_NAME --style-file=$STYLE_LOC $SPLIT_LOC/*.osm.pbf
echo 'Generating transport map....done'
merge_all
#send_map
# ------------- End -------------
