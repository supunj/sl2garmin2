#!/bin/bash

MAP_ROOT=$(dirname $(readlink -f $0))
TEMP_LOC=$MAP_ROOT/tmp
HGT_LOC=$MAP_ROOT/hgt

mkdir $TEMP_LOC/srtm
cd $TEMP_LOC/srtm

for file in `find $HGT_LOC -maxdepth 1 -type f -name "*.hgt"`
do
	phyghtmap -s 5 --pbf $file
done

cd $MAP_ROOT
