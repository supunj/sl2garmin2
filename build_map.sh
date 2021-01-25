#!/bin/bash

#Author: Supun Jayathilake (supunj@gmail.com)

function prepare()
{
	# Content locations
	MAP_ROOT=$(dirname $(readlink -f $0))
	TEMP_LOC=$MAP_ROOT/tmp
	IMG_LOC=$TEMP_LOC/Garmin
	OTHER_IMG_LOC=$MAP_ROOT/maps/img
	
	# Tools
	MKGMAP=$MAP_ROOT/tools/mkgmap-r4594/mkgmap.jar
	OSMOSIS_LOC=$MAP_ROOT/tools/osmosis-0.48.3
	OSMOSIS=$OSMOSIS_LOC/bin/osmosis
	SPLITTER=$MAP_ROOT/tools/splitter-r597/splitter.jar
	STYLE_TRANSPORT=sl
	STYLE_CONTOURS=sl
	TYP_FILE=$MAP_ROOT/typ/os50_mod.typ

	export MKGMAP_JAVACMD=/usr/bin/java
	export MKGMAP_JAVACMD_OPTIONS="-Xmx4096M -jar -enableassertions"

	rm -rf $TEMP_LOC
	mkdir -p $TEMP_LOC/poi
	mkdir -p $TEMP_LOC/typ
  	mkdir -p $TEMP_LOC/gpi
	mkdir -p $IMG_LOC/mapset
	mkdir -p $MAP_ROOT/tmp/split
	
	#Download if map does not exists
	if [ -f "$MAP_ROOT/maps/sri-lanka-latest.osm.pbf" ]; then
    		# Copy map	
		cp $MAP_ROOT/maps/sri-lanka-latest.osm.pbf $TEMP_LOC/sri-lanka-latest.osm.pbf
	else 
    		echo "Downloading latest map...."
	fi
}

function build_sea_and_the_land()
{
	echo "Extracting the coastline..."
        $OSMOSIS \
        	--read-pbf-fast file=$TEMP_LOC/sri-lanka-latest.osm.pbf \
        	--way-key-value keyValueList="natural.coastline" \
        	--tf reject-relations \
        	--used-node \
        	--write-pbf $TEMP_LOC/sri-lanka-latest-coastline.osm.pbf
	echo "Extracting the coastline...done."
	
	cd $IMG_LOC
	
	echo 'Sea and the land....'
	IMG_FILE_NAME="`shuf -i 10000000-99999999 -n 1`"
	$MKGMAP_JAVACMD \
	$MKGMAP_JAVACMD_OPTIONS \
	$MKGMAP \
		-c $MAP_ROOT/arg/sea_land.args \
		--dem=$MAP_ROOT/hgt \
		--description=Contours \
		--mapname=$IMG_FILE_NAME \
		--style-file=$MAP_ROOT/style \
		--style=$STYLE_CONTOURS \
		$TEMP_LOC/sri-lanka-latest-coastline.osm.pbf
	echo 'Sea and the land........done'
	cd $MAP_ROOT
}

function build_contour_lines()
{
	cd $IMG_LOC
	echo 'Generating contour lines....'
	IMG_FILE_NAME="`shuf -i 10000000-99999999 -n 1`"
	$MKGMAP_JAVACMD \
	$MKGMAP_JAVACMD_OPTIONS \
	$MKGMAP \
		-c $MAP_ROOT/arg/elevation.args \
		--description=Contours \
		--mapname=$IMG_FILE_NAME \
		--style-file=$MAP_ROOT/style \
		--style=$STYLE_CONTOURS \
		$MAP_ROOT/maps/srtm/*.osm.pbf
	echo 'Generating contour lines....done'
	cd $MAP_ROOT
}

function build_roads_and_areas()
{
	echo "Extracting ways and polygons..."
        $OSMOSIS \
        	--read-pbf-fast file=$TEMP_LOC/sri-lanka-latest.osm.pbf \
        	--tf accept-ways \
        	--tf reject-ways natural=coastline \
        	--tf accept-relations \
        	--used-node \
        	--write-pbf $TEMP_LOC/sri-lanka-latest-transport.osm.pbf
	echo "Extracting ways and polygons...done."
	
	echo 'Splitting....'
	cd $MAP_ROOT/tmp/split
	$MKGMAP_JAVACMD \
	$MKGMAP_JAVACMD_OPTIONS \
	$SPLITTER $TEMP_LOC/sri-lanka-latest-transport.osm.pbf
	echo 'Splitting done.'
	cd $MAP_ROOT
	
	cd $IMG_LOC
	echo 'Generating transport map....'
	IMG_FILE_NAME="`shuf -i 10000000-99999999 -n 1`"
	$MKGMAP_JAVACMD \
	$MKGMAP_JAVACMD_OPTIONS \
	$MKGMAP \
		-c $MAP_ROOT/arg/transport_osm.args \
		--description=Transport \
		--mapname=$IMG_FILE_NAME \
		--style-file=$MAP_ROOT/style \
		--style=$STYLE_TRANSPORT \
		$MAP_ROOT/tmp/split/*.osm.pbf
	echo 'Generating transport map....done'
	cd $MAP_ROOT
}

function build_pois()
{	
	echo "Extracting POIs..."
        $OSMOSIS \
        	--read-pbf-fast file=$TEMP_LOC/sri-lanka-latest.osm.pbf \
        	--tf accept-nodes \
        		amenity=* \
        		tourism=* \
        		highway=* \
        		leisure=* \
        		historic=* \
        		natural=* \
        		railway=* \
        		shop=* \
        		public_transport=* \
        		barrier=* \
        		man_made=* \
        		landmark=* \
        		natural=* \
        		sport=* \
        	--tf reject-ways \
        	--tf reject-relations \
        	--write-pbf $TEMP_LOC/sri-lanka-latest-poi.osm.pbf
	echo "Extracting POIs...done."
	
	cd $IMG_LOC
	echo 'Generating POI map....'
	IMG_FILE_NAME="`shuf -i 10000000-99999999 -n 1`"
	$MKGMAP_JAVACMD \
	$MKGMAP_JAVACMD_OPTIONS \
	$MKGMAP \
		-c $MAP_ROOT/arg/poi.args \
		--description=POI \
		--mapname=$IMG_FILE_NAME \
		--style-file=$MAP_ROOT/style \
		--style=$STYLE_TRANSPORT \
		--input-file=$TEMP_LOC/sri-lanka-latest-poi.osm.pbf
	echo 'Generating POI map....done'
	cd $MAP_ROOT
}

function merge_all()
{
	#Copy other pre-compiled maps
	#echo 'Copying pre-compiled maps...'
	#cp $OTHER_IMG_LOC/*.img $IMG_LOC
	#echo 'Copying pre-compiled maps...done'

	#Combine all img files into one
	IMG_STRING=''
	for file in `find $IMG_LOC -maxdepth 1 -type f -name "*.img" -o -name "*.mdx"`
	do
		IMG_STRING="$IMG_STRING $file"
	done

	cd $IMG_LOC/mapset
	echo "Combining all maps...."
	$MKGMAP_JAVACMD \
	$MKGMAP_JAVACMD_OPTIONS -jar $MKGMAP \
		--code-page=1252 \
		--keep-going \
		--gmapsupp \
		--tdbfile \
		--index \
		$IMG_STRING \
		$TYP_FILE
	echo 'Combining done.'
	cd $MAP_ROOT
}

function create_gpi()
{
	$OSMOSIS \
		--read-pbf file=$TEMP_LOC/sri-lanka-latest.osm.pbf \
		--tf reject-ways \
		--tf reject-relations \
		--node-key-value keyValueList="amenity.school" \
		--write-xml file=$TEMP_LOC/school.osm
	gpsbabel \
		-i osm \
		-f $TEMP_LOC/school.osm \
		-o garmin_gpi,category="Schools",alerts=1,proximity=1km \
		-F $TEMP_LOC/gpi/school.gpi

	$OSMOSIS \
		--read-pbf file=$TEMP_LOC/sri-lanka-latest.osm.pbf \
		--tf reject-ways \
		--tf reject-relations \
		--node-key-value keyValueList="amenity.police" \
		--write-xml file=$TEMP_LOC/police.osm
	gpsbabel \
		-i osm \
		-f $TEMP_LOC/police.osm \
		-o garmin_gpi,category="Police",alerts=1,proximity=3km \
		-F $TEMP_LOC/gpi/police.gpi

	$OSMOSIS \
		--read-pbf file=$TEMP_LOC/sri-lanka-latest.osm.pbf \
		--tf reject-ways \
		--tf reject-relations \
		--node-key-value keyValueList="highway.traffic_signals" \
		--write-xml file=$TEMP_LOC/signals.osm
	gpsbabel \
		-i osm \
		-f $TEMP_LOC/signals.osm \
		-o garmin_gpi,category="Traffic Lights",alerts=1,proximity=0.5km \
		-F $TEMP_LOC/gpi/signals.gpi
}

# ------------- Start -------------
prepare
build_sea_and_the_land
build_contour_lines
build_roads_and_areas
build_pois
#create_gpi
merge_all
#send_map
# ------------- End -------------
