#!/bin/bash

#Author: Supun Jayathilake (supunj@gmail.com)

MAP_ROOT=$(dirname $(readlink -f $0))
OSMOSIS_LOC=$MAP_ROOT/tools/osmosis-0.48.3
OSMOSIS=$OSMOSIS_LOC/bin/osmosis

sudo -u postgres dropdb osm
sudo -u postgres createdb osm

sudo -u postgres psql -d osm -c "CREATE EXTENSION postgis"
sudo -u postgres psql -d osm -c "CREATE EXTENSION postgis_topology"
sudo -u postgres psql -d osm -c "CREATE EXTENSION fuzzystrmatch"
sudo -u postgres psql -d osm -c "CREATE EXTENSION postgis_tiger_geocoder"
sudo -u postgres psql -d osm -c "CREATE EXTENSION hstore"
sudo -u postgres psql -d osm -c "CREATE EXTENSION intarray"

sudo -u postgres psql -d osm -f $OSMOSIS_LOC/script/pgsnapshot_schema_0.6.sql
#sudo -u postgres psql -d osm -f $OSMOSIS_LOC/script/pgsnapshot_schema_0.6_action.sql
#sudo -u postgres psql -d osm -f $OSMOSIS_LOC/script/pgsnapshot_schema_0.6_bbox.sql
#sudo -u postgres psql -d osm -f $OSMOSIS_LOC/script/pgsnapshot_schema_0.6_linestring.sql
#sudo -u postgres psql -d osm -f $OSMOSIS_LOC/script/pgsnapshot_load_0.6.sql


#$OSMOSIS --read-xml file=/media/common/Temp/sri_lanka_coastline.osm --write-pgsql host="localhost" database="osm" user="osm" password='osm'
$OSMOSIS --read-pbf-fast file=$MAP_ROOT/maps/sri-lanka-latest.osm.pbf --write-pgsql host="localhost" database="osm" user="postgres" password='postgres'

#echo 'Fixing data....'
#sudo -u postgres psql -d osm -f $PG_LOC/split_roads.sql > $TEMP_LOC/result.txt
#sudo -u postgres psql -d osm -f $PG_LOC/fix_data.sql > $TEMP_LOC/result.txt

#$OSMOSIS --read-pgsql host="localhost" database="osm" user="postgres" password='postgres' outPipe.0=pg --dd inPipe.0=pg outPipe.0=dd --write-pbf inPipe.0=dd file=$TEMP_LOC/sri-lanka-latest.osm.pbf
