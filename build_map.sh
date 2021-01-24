#!/bin/bash

#Author: Supun Jayathilake (supunj@gmail.com)

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
	GPI_LOC=$TEMP_LOC/gpi
	ARG_LOC=$MAP_ROOT/arg
	SPLIT_LOC=$MAP_ROOT/tmp/split
	STYLE_LOC=$MAP_ROOT/style
	ICON_LOC=$MAP_ROOT/icon
	TYP_LOC=$MAP_ROOT/typ
	HGT_LOC=$MAP_ROOT/hgt
	
	# Tools
	MKGMAP=$MAP_ROOT/tools/mkgmap-r4594/mkgmap.jar
	OSMOSIS_LOC=$MAP_ROOT/tools/osmosis-0.48.3
	OSMOSIS=$OSMOSIS_LOC/bin/osmosis
	SPLITTER=$MAP_ROOT/tools/splitter-r597/splitter.jar
	COASTLINE=$MAP_ROOT/maps/sri_lanka_coastline_v6.osm
	STYLE_TRANSPORT=sl
	STYLE_CONTOURS=sl

	export MKGMAP_JAVACMD=/usr/bin/java
	export MKGMAP_JAVACMD_OPTIONS="-Xmx4096M -jar -enableassertions"

	rm -rf $TEMP_LOC
	mkdir -p $TEMP_LOC/poi
	mkdir -p $TEMP_LOC/typ
  	mkdir -p $GPI_LOC
	mkdir -p $IMG_LOC/mapset
	mkdir -p $SPLIT_LOC
	
	#Download if map does not exists
	if [ -f "$MAP_ROOT/maps/sri-lanka-latest.osm.pbf" ]; then
    		# Copy map	
		cp $MAP_ROOT/maps/sri-lanka-latest.osm.pbf $TEMP_LOC/sri-lanka-latest.osm.pbf
	else 
    		echo "Downloading latest map...."
	fi

	echo "Extracting ways and polygons..."
        $OSMOSIS --read-pbf-fast file=$TEMP_LOC/sri-lanka-latest.osm.pbf --tf accept-ways --tf reject-ways natural=coastline --tf accept-relations --used-node --write-pbf $TEMP_LOC/sri-lanka-latest-transport.osm.pbf
	echo "Extracting ways and polygons...done."

	echo "Extracting POIs..."
        $OSMOSIS --read-pbf-fast file=$TEMP_LOC/sri-lanka-latest.osm.pbf --tf accept-nodes amenity=* tourism=* highway=* leisure=* historic=* natural=* railway=* shop=* public_transport=* barrier=* man_made=* landmark=* natural=* sport=* --tf reject-ways --tf reject-relations --write-pbf $TEMP_LOC/sri-lanka-latest-poi.osm.pbf
	echo "Extracting POIs...done."
	
	echo 'Splitting....'
	cd $SPLIT_LOC
	$MKGMAP_JAVACMD $MKGMAP_JAVACMD_OPTIONS $SPLITTER $TEMP_LOC/sri-lanka-latest.osm.pbf
	echo 'Splitting done.'
	cd $MAP_ROOT

	#cp $MAP_ROOT/maps/srtm/* $SPLIT_LOC

	#cat $TYP_LOC/os50mod/header.txt $TYP_LOC/os50mod/polygon.txt $TYP_LOC/os50mod/line.txt $TYP_LOC/os50mod/poi.txt > $TEMP_LOC/typ/os50mod.txt
	#TYP_FILE=$TEMP_LOC/typ/os50mod.txt
	#cat $TYP_LOC/os50mod/header.txt $TYP_LOC/os50mod/polygon.txt > $TEMP_LOC/typ/os50mod.txt
	#TYP_FILE=$TEMP_LOC/typ/jbm.txt
	TYP_FILE=$TYP_LOC/os50_mod.typ
}

function create_gpi()
{
        #for tag in "amenity" "tourism" "highway" "leisure" "historic" "natural" "railway" "shop" "public_transport" "barrier" "man_made" "landmark" "natural" "sport"
        #do
        #        echo "Extracting POIs - $tag"
        #        $OSMOSIS --read-pbf file=$TEMP_LOC/sri-lanka-latest.osm.pbf --tf reject-ways --tf reject-relations --tf accept-nodes $tag=* --write-xml $TEMP_LOC/poi/sri-lanka-latest.osm_$tag.osm
	#	gpsbabel -i osm -f $TEMP_LOC/poi/sri-lanka-latest.osm_$tag.osm -o garmin_gpi,category=$tag,bitmap=$ICON_LOC/$tag.bmp -F $GPI_LOC/$tag.gpi
        #done	
	#echo "Done!"

	$OSMOSIS --read-pbf file=$TEMP_LOC/sri-lanka-latest.osm.pbf --tf reject-ways --tf reject-relations --node-key-value keyValueList="amenity.school" --write-xml file=$TEMP_LOC/school.osm
	gpsbabel -i osm -f $TEMP_LOC/school.osm -o garmin_gpi,category="Schools",alerts=1,proximity=1km -F $GPI_LOC/school.gpi

	$OSMOSIS --read-pbf file=$TEMP_LOC/sri-lanka-latest.osm.pbf --tf reject-ways --tf reject-relations --node-key-value keyValueList="amenity.police" --write-xml file=$TEMP_LOC/police.osm
	gpsbabel -i osm -f $TEMP_LOC/police.osm -o garmin_gpi,category="Police",alerts=1,proximity=3km -F $GPI_LOC/police.gpi

	$OSMOSIS --read-pbf file=$TEMP_LOC/sri-lanka-latest.osm.pbf --tf reject-ways --tf reject-relations --node-key-value keyValueList="highway.traffic_signals" --write-xml file=$TEMP_LOC/signals.osm
	gpsbabel -i osm -f $TEMP_LOC/signals.osm -o garmin_gpi,category="Traffic Lights",alerts=1,proximity=0.5km -F $GPI_LOC/signals.gpi
}

# ------------- Start -------------
prepare
#create_gpi

# Start building maps
cd $IMG_LOC

echo 'Generating transport map....'
IMG_FILE_NAME="`shuf -i 10000000-99999999 -n 1`"
$MKGMAP_JAVACMD $MKGMAP_JAVACMD_OPTIONS $MKGMAP -c $ARG_LOC/transport_osm.args --description=Transport --mapname=$IMG_FILE_NAME --style-file=$STYLE_LOC --style=$STYLE_TRANSPORT $SPLIT_LOC/*.osm.pbf
echo 'Generating transport map....done'

echo 'Generating POI map....'
IMG_FILE_NAME="`shuf -i 10000000-99999999 -n 1`"
$MKGMAP_JAVACMD $MKGMAP_JAVACMD_OPTIONS $MKGMAP -c $ARG_LOC/poi.args --description=POI --mapname=$IMG_FILE_NAME --style-file=$STYLE_LOC --style=$STYLE_TRANSPORT --input-file=$TEMP_LOC/sri-lanka-latest-poi.osm.pbf
echo 'Generating POI map....done'

echo 'Generating contour lines....'
IMG_FILE_NAME="`shuf -i 10000000-99999999 -n 1`"
$MKGMAP_JAVACMD $MKGMAP_JAVACMD_OPTIONS $MKGMAP -c $ARG_LOC/elevation.args --dem=$HGT_LOC --description=Contours --coastlinefile=$COASTLINE --mapname=$IMG_FILE_NAME --style-file=$STYLE_LOC --style=$STYLE_CONTOURS $MAP_ROOT/maps/srtm/*.osm.pbf
echo 'Generating contour lines....done'

merge_all
#send_map
# ------------- End -------------
