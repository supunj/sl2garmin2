#!/bin/bash

#Author: Supun Jayathilake (supunj@gmail.com)

function prepare()
{
	# Content locations
	MAP_ROOT=$(dirname $(readlink -f $0))
	TEMP_LOC=$MAP_ROOT/tmp
	OSMOSIS_LOC=$MAP_ROOT/tools/osmosis-0.48.3
	OSMOSIS=$OSMOSIS_LOC/bin/osmosis	
	SOURCE_MAP_NAME=sri-lanka-latest.osm.pbf
	
	rm -rf $TEMP_LOC/gpi
	rm -rf $TEMP_LOC/poi
  	mkdir -p $TEMP_LOC/gpi
  	mkdir -p $TEMP_LOC/poi
	
	echo "Extracting POIs..."
        $OSMOSIS \
        	--read-pbf-fast file=$MAP_ROOT/maps/$SOURCE_MAP_NAME \
        	--tf accept-nodes \
        	--tf reject-ways \
        	--tf reject-relations \
        	--write-pbf $TEMP_LOC/sri-lanka-latest-poi.osm.pbf
	echo "Extracting POIs...done."
}

function create_gpi()
{	
	for tag in $(cat $MAP_ROOT/tags.conf)
        do
                echo "Extracting POIs - $tag"                
                tag_string=(${tag//:/ })
                $OSMOSIS \
                	--read-pbf file=$TEMP_LOC/sri-lanka-latest-poi.osm.pbf \
                	--tf reject-ways \
                	--tf reject-relations \
                	--tf accept-nodes \
                	--node-key-value keyValueList="${tag_string[1]}" \
                	--write-xml $TEMP_LOC/poi/sri-lanka-latest.osm_${tag_string[0]}.osm
                	
                if [ "${tag_string[2]}" == '' ]
                then
	    		gpsbabel \
				-i osm \
				-f $TEMP_LOC/poi/sri-lanka-latest.osm_${tag_string[0]}.osm \
				-o garmin_gpi,descr,category=${tag_string[0]},bitmap=$MAP_ROOT/icons/${tag_string[0]}.bmp \
				-F $TEMP_LOC/gpi/${tag_string[0]}.gpi
		else
    			gpsbabel \
				-i osm \
				-f $TEMP_LOC/poi/sri-lanka-latest.osm_${tag_string[0]}.osm \
				-o garmin_gpi,descr,category=${tag_string[0]},bitmap=$MAP_ROOT/icons/${tag_string[0]}.bmp,${tag_string[2]} \
				-F $TEMP_LOC/gpi/${tag_string[0]}.gpi
		fi
        done
}

prepare
create_gpi
