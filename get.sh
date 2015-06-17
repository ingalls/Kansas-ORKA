#/usr/bin/env bash

OLDIFS=$IFS

# Usage: filesafe "filename"
# Returns a valid file/folder name 
function _filesafe() {
    if [[ -z $1 ]]; then exit 1; fi  
    echo $(echo "$1" | sed -e 's/[^A-Za-z0-9._-]/_/g') 
}

mkdir $(dirname $0)/data &>/dev/null|| true

echo "# KS Parcel Extract"
echo "# -----------------"

echo "# Downloading county list"
COUNTIES=$(curl -s http://mapserver.kansasgis.org/arcgis/rest/services/ORKA | grep -Po "[A-Z]{2}_ORKA" | sort | uniq)
echo "ok - Downloaded county list"

for COUNTY in $COUNTIES; do
    COUNTYSAFE=$(_filesafe "$COUNTY")
    echo "# Downloading Layers for $COUNTY"

    #setup  & clear output paths
    mkdir $(dirname $0)/data/$COUNTYSAFE &>/dev/null || true

    if [[ $1 != "skip" ]]; then
        rm $(dirname $0)/data/$COUNTYSAFE/* &>/dev/null || true
    fi

    curl -s http://mapserver.kansasgis.org/arcgis/rest/services/ORKA/$COUNTY/MapServer \
        | grep -Po "<a href=\"/arcgis/rest/services/ORKA/$COUNTY/MapServer/\d+\">.*?</a>" \
        | sed -e 's/\\"/\\\"/g' \
        | while read LAYER; do
            ID=$(echo $LAYER | grep -Po "MapServer\/\d+" | sed 's/MapServer\///')
            NAME=$(echo $LAYER | grep -Po ">.*" | sed -e 's/>//' -e 's/<\/a>//')
            NAMESAFE=$(_filesafe "$NAME")
            echo "# Processing $NAME ($ID)"

            TYPE="$(curl -s http://mapserver.kansasgis.org/arcgis/rest/services/ORKA/$COUNTY/MapServer/$ID \
                | grep "Geometry Type")"

            if [[ -z $(echo $TYPE | grep -Po "esri[A-Z|a-z]+") ]]; then
                echo "not ok - skipping layer - no geometry"
            elif [[ $1 == "skip" ]] && [[ -e $(dirname $0)/data/$COUNTYSAFE/${NAMESAFE}.geojson ]]; then
                echo "ok - layer exists - skipping"
            else
                TYPE=$(echo $TYPE | grep -Po "esri[A-Z|a-z]+")

                geomCount=0
                echo "# Downloaded 0 geometries"
                esri-dump "http://mapserver.kansasgis.org/arcgis/rest/services/ORKA/$COUNTY/MapServer/$ID" \
                    | while read -r GEOM; do
                        geomCount=$((geomCount+1))
                        echo -e "\e[1A# Downloaded $geomCount geometries"
                        echo "$GEOM" >> $(dirname $0)/data/$COUNTYSAFE/${NAMESAFE}.geojson
                    done || true
                head -n -1 $(dirname $0)/data/$COUNTYSAFE/${NAMESAFE}.geojson > $(dirname $0)/data/$COUNTYSAFE/${NAMESAFE}.geojson.tmp
                mv $(dirname $0)/data/$COUNTYSAFE/${NAMESAFE}.geojson.tmp $(dirname $0)/data/$COUNTYSAFE/${NAMESAFE}.geojson
                echo "]}" >> $(dirname $0)/data/$COUNTYSAFE/${NAMESAFE}.geojson
                gzip $(dirname $0)/data/$COUNTYSAFE/${NAMESAFE}.geojson
            fi
        done
done
