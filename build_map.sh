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
	MKGMAP=$MAP_ROOT/tools/mkgmap-r4816/mkgmap.jar
	OSMOSIS_LOC=$MAP_ROOT/tools/osmosis-0.48.3
	OSMOSIS=$OSMOSIS_LOC/bin/osmosis
	SPLITTER=$MAP_ROOT/tools/splitter-r643/splitter.jar

	FID=53130
	PID=1
	SNAME=sl-topo
	AREA=sl

	export MKGMAP_JAVACMD=/usr/bin/java
	export MKGMAP_JAVACMD_OPTIONS="-Xmx4096M -jar -enableassertions"

	rm -rf $TEMP_LOC
	mkdir -p $IMG_LOC/mapset
	mkdir -p $MAP_ROOT/tmp/split
	
	SOURCE_MAP_NAME=sri-lanka-latest.osm.pbf
	
	#Download if map does not exists
	if [ -f "$MAP_ROOT/maps/$SOURCE_MAP_NAME" ]; then
    		# Copy map	
		cp $MAP_ROOT/maps/$SOURCE_MAP_NAME $TEMP_LOC/$SOURCE_MAP_NAME
	else 
    		echo "Downloading latest map...."
	fi
}

function build_base_map()
{
	echo "Extracting the coastline..."
	$OSMOSIS \
		--read-pbf-fast file=$TEMP_LOC/$SOURCE_MAP_NAME \
		--tf accept-ways natural=coastline \
		--tf reject-relations \
		--bounding-polygon file=$MAP_ROOT/sri-lanka.poly \
		--used-node \
		--write-pbf $TEMP_LOC/sri-lanka-latest-coastline.osm.pbf
	
	cd $IMG_LOC
	echo 'Building base map....'
	IMG_FILE_NAME="`shuf -i 10000000-99999999 -n 1`"
	$MKGMAP_JAVACMD \
	$MKGMAP_JAVACMD_OPTIONS \
	$MKGMAP \
		-c $MAP_ROOT/arg/sea_land.args \
		--family-id=$FID \
		--product-id=$PID \
		--series-name=$SNAME \
		--area-name=$AREA \
		--mapname=$IMG_FILE_NAME \
		--dem=$MAP_ROOT/hgt \
		--dem-poly=$MAP_ROOT/sri-lanka.poly \
		--style-file=$MAP_ROOT/style \
		--style=lk \
		$TEMP_LOC/sri-lanka-latest-coastline.osm.pbf	
	cd $MAP_ROOT
}

function build_contour_lines()
{
	echo 'Splitting contour lines....'
	rm $MAP_ROOT/tmp/split/*
	cd $MAP_ROOT/tmp/split
	$MKGMAP_JAVACMD \
	$MKGMAP_JAVACMD_OPTIONS \
	$SPLITTER \
		--polygon-file=$MAP_ROOT/sri-lanka.poly \
		$MAP_ROOT/maps/sl-contours.osm.pbf
	cd $MAP_ROOT
	
	cd $IMG_LOC
	echo 'Building contour map....'
	IMG_FILE_NAME="`shuf -i 10000000-99999999 -n 1`"
	$MKGMAP_JAVACMD \
	$MKGMAP_JAVACMD_OPTIONS \
	$MKGMAP \
		-c $MAP_ROOT/arg/elevation.args \
		--family-id=$FID \
		--product-id=$PID \
		--series-name=$SNAME \
		--area-name=$AREA \
		--mapname=$IMG_FILE_NAME \
		--style-file=$MAP_ROOT/style \
		--style=lk \
		$MAP_ROOT/tmp/split/*.osm.pbf
	cd $MAP_ROOT
}

function build_ways_relations_pois()
{
	echo "Process..."
        $OSMOSIS \
        	--read-pbf-fast file=$TEMP_LOC/$SOURCE_MAP_NAME \
        	--tf accept-nodes \
        	--tf accept-ways \
        	--tf accept-relations \
        	--tf reject-relations name='Gulf of Mannar' \
        	--bounding-polygon file=$MAP_ROOT/sri-lanka.poly \
        	--write-pbf $TEMP_LOC/sri-lanka-latest-no-coast-relations.osm.pbf
        	
	echo 'Splitting....'
	rm $MAP_ROOT/tmp/split/*
	cd $MAP_ROOT/tmp/split
	$MKGMAP_JAVACMD \
	$MKGMAP_JAVACMD_OPTIONS \
	$SPLITTER \
		--polygon-file=$MAP_ROOT/sri-lanka.poly \
		$TEMP_LOC/sri-lanka-latest-no-coast-relations.osm.pbf	
	cd $MAP_ROOT
	
	cd $IMG_LOC
	echo 'Building....'
	IMG_FILE_NAME="`shuf -i 10000000-99999999 -n 1`"
	$MKGMAP_JAVACMD \
	$MKGMAP_JAVACMD_OPTIONS \
	$MKGMAP \
		-c $MAP_ROOT/arg/transport_osm.args \
		--family-id=$FID \
		--product-id=$PID \
		--series-name=$SNAME \
		--area-name=$AREA \
		--mapname=$IMG_FILE_NAME \
		--style-file=$MAP_ROOT/style \
		--style=lk \
		$MAP_ROOT/tmp/split/*.osm.pbf
	cd $MAP_ROOT
}

function merge_all()
{
	IMG_STRING=''
	for file in `find $IMG_LOC -maxdepth 1 -type f -name "*.img"`
	do
		IMG_STRING="$IMG_STRING $file"
	done

	cd $IMG_LOC/mapset
	echo "Combining all maps...."
	$MKGMAP_JAVACMD \
	$MKGMAP_JAVACMD_OPTIONS -jar \
	$MKGMAP \
		--family-id=$FID \
		--product-id=$PID \
		--series-name=$SNAME \
		--area-name=$AREA \
		--keep-going \
		--gmapsupp \
		--tdbfile \
		--index \
		$IMG_STRING \
		$MAP_ROOT/typ/os50_mod.typ
	cd $MAP_ROOT
}

function build_one_map()
{
	prepare
	build_base_map
	build_contour_lines
	build_ways_relations_pois
	merge_all
}

function build_individual_maps()
{
	prepare
	build_base_map
	merge_all
	mv $IMG_LOC/mapset/gmapsupp.img $IMG_LOC/mapset/sl-base.img
	rm $IMG_LOC/*.img $IMG_LOC/mapset/osmmap*
	build_contour_lines
	merge_all
	mv $IMG_LOC/mapset/gmapsupp.img $IMG_LOC/mapset/sl-contour.img
	rm $IMG_LOC/*.img $IMG_LOC/mapset/osmmap*
	build_ways_relations_pois
	merge_all
	mv $IMG_LOC/mapset/gmapsupp.img $IMG_LOC/mapset/sl-road.img
	mv $IMG_LOC/mapset/osmmap_mdr.img $IMG_LOC/mapset/sl-road_mdr.img
	mv $IMG_LOC/mapset/osmmap.mdx $IMG_LOC/mapset/sl-road.mdx
	rm $IMG_LOC/*.img $IMG_LOC/mapset/osmmap*
}

function build_road_map()
{	
	prepare
	build_ways_relations_pois
	merge_all
	mv $IMG_LOC/mapset/gmapsupp.img $IMG_LOC/mapset/sl-road.img
	mv $IMG_LOC/mapset/osmmap_mdr.img $IMG_LOC/mapset/sl-road_mdr.img
	mv $IMG_LOC/mapset/osmmap.mdx $IMG_LOC/mapset/sl-road.mdx
	rm $IMG_LOC/*.img $IMG_LOC/mapset/osmmap*
}

# ------------- Start -------------
build_individual_maps
#build_road_map
#build_one_map
# ------------- End -------------
