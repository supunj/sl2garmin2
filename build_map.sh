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
	STYLE_SL=sl
	TYP_FILE=$MAP_ROOT/typ/os50_mod.typ
	#TYP_FILE=$MAP_ROOT/typ/test.typ

	export MKGMAP_JAVACMD=/usr/bin/java
	export MKGMAP_JAVACMD_OPTIONS="-Xmx4096M -jar -enableassertions"

	rm -rf $TEMP_LOC
	mkdir -p $TEMP_LOC/poi
	mkdir -p $TEMP_LOC/typ
	mkdir -p $IMG_LOC/mapset
	mkdir -p $MAP_ROOT/tmp/split
	
	SOURCE_MAP_NAME=sri-lanka-latest.osm.pbf
	#SOURCE_MAP_NAME=sri-lanka-latest.osm.pbf.temp
	
	#Download if map does not exists
	if [ -f "$MAP_ROOT/maps/$SOURCE_MAP_NAME" ]; then
    		# Copy map	
		cp $MAP_ROOT/maps/$SOURCE_MAP_NAME $TEMP_LOC/$SOURCE_MAP_NAME
	else 
    		echo "Downloading latest map...."
	fi
}

function build_sea_and_the_land()
{
	echo "Extracting the coastline..."
        $OSMOSIS \
        	--read-pbf-fast file=$TEMP_LOC/$SOURCE_MAP_NAME \
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
		--description="Sea and the land" \
		--mapname=$IMG_FILE_NAME \
		--style-file=$MAP_ROOT/style \
		--style=$STYLE_CONTOURS \
		$TEMP_LOC/sri-lanka-latest-coastline.osm.pbf
	echo 'Sea and the land........done'
	cd $MAP_ROOT
}

function all_in_one()
{
	echo "Extracting the lines and relations..."
        $OSMOSIS \
        	--read-pbf-fast file=$TEMP_LOC/$SOURCE_MAP_NAME \
        	--tf accept-ways \
        	--tf accept-relations \
        	--used-node \
        	--write-pbf $TEMP_LOC/sri-lanka-latest-poi-less.osm.pbf
	echo "Extracting the lines and relations...done."
	
	echo 'Splitting....'
	cd $MAP_ROOT/tmp/split
	$MKGMAP_JAVACMD \
	$MKGMAP_JAVACMD_OPTIONS \
	$SPLITTER $TEMP_LOC/sri-lanka-latest-poi-less.osm.pbf
	echo 'Splitting done.'
	cd $MAP_ROOT
	
	echo "Copying SRTM data...."
	cp $MAP_ROOT/maps/srtm/*.osm.pbf $MAP_ROOT/tmp/split
	
	
	cd $IMG_LOC
	echo 'Building all in one map....'
	IMG_FILE_NAME="`shuf -i 10000000-99999999 -n 1`"
	$MKGMAP_JAVACMD \
	$MKGMAP_JAVACMD_OPTIONS \
	$MKGMAP \
		-c $MAP_ROOT/arg/all_in_one.args \
		--dem=$MAP_ROOT/hgt \
		--description="Sea, land and the roads" \
		--mapname=$IMG_FILE_NAME \
		--style-file=$MAP_ROOT/style \
		--style=$STYLE_SL \
		$MAP_ROOT/tmp/split/*.osm.pbf \
		$TYP_FILE
	echo 'Building all in one map....done'
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
        	--read-pbf-fast file=$TEMP_LOC/$SOURCE_MAP_NAME \
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
        	--read-pbf-fast file=$TEMP_LOC/$SOURCE_MAP_NAME \
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
	$MKGMAP_JAVACMD_OPTIONS -jar \
	$MKGMAP \
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

# ------------- Start -------------
prepare
all_in_one
#build_sea_and_the_land
#build_contour_lines
#build_roads_and_areas
#build_pois
#merge_all
#send_map
# ------------- End -------------
