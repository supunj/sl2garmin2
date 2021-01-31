#!/bin/bash

#Author: Supun Jayathilake (supunj@gmail.com)

function prepare()
{
	# Content locations
	MAP_ROOT=$(dirname $(readlink -f $0))
	TEMP_LOC=$MAP_ROOT/tmp
	OSMOSIS_LOC=$MAP_ROOT/tools/osmosis-0.48.3
	OSMOSIS=$OSMOSIS_LOC/bin/osmosis
	
	rm -rf $TEMP_LOC/gpi	
  	mkdir -p $TEMP_LOC/gpi
  	mkdir -p $TEMP_LOC/poi
	
	SOURCE_MAP_NAME=sri-lanka-latest.osm.pbf
}

function create_gpi()
{	
	for tag in $(cat $MAP_ROOT/tags.conf)
        do
                echo "Extracting POIs - $tag"
                $OSMOSIS \
                	--read-pbf file=$TEMP_LOC/sri-lanka-latest.osm.pbf \
                	--tf reject-ways \
                	--tf reject-relations \
                	--tf accept-nodes \
                	--node-key-value keyValueList="$tag" \
                	--write-xml $TEMP_LOC/poi/sri-lanka-latest.osm_$tag.osm
		gpsbabel \
			-i osm \
			-f $TEMP_LOC/poi/sri-lanka-latest.osm_$tag.osm \
			-o garmin_gpi,category=$tag,bitmap=$MAP_ROOT/icons/$tag.bmp \
			-F $TEMP_LOC/gpi/$tag.gpi
        done	
	echo "Done!"


	$OSMOSIS \
		--read-pbf file=$TEMP_LOC/$SOURCE_MAP_NAME \
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
		--read-pbf file=$TEMP_LOC/$SOURCE_MAP_NAME \
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
		--read-pbf file=$TEMP_LOC/$SOURCE_MAP_NAME \
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

prepare
create_gpi
