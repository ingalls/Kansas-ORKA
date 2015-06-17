#/usr/bin/env bash

# Process Parcel Layer

COUNTIES=$(find $(dirname $0)/data -type d | wc -l)
echo "Processing $COUNTIES Counties"

# Create files
echo "{\"type\":\"FeatureCollection\",\"features\":[" > $(dirname $0)/data/parcels.geojson

find $(dirname $0)/data/ -type f -regex ".*.gz" \
    | while read file; do

        # if [[ $file == *Parcels.geojson.gz ]]; then
        # echo "# +=> single parcel layer ($file)"
        #     gzip -dc $(dirname $0)/$file \
        #         | jq -r -c '.features | . []' | while read line; do
        #             echo "$line,">> $(dirname $0)/data/parcels.geojson
        #         done
        # fi
        #
        #
        # if [[ $file == "Roads.geojson.gz" ]]; then
        #     echo "# +=> road layer ($file)"
        #     gzip -dc $(dirname $0)/$file \
        #         | jq -r -c '.features | . []' | while read line; do
        #             echo "$line,">> $(dirname $0)/data/parcels.geojson
        #         done
        # fi

        echo "# => addess layer ($file)"
        gzip -dc $(dirname $0)/$file \
            | $(dirname $0)/node_modules/turf-cli/turf-point-on-surface.js \
            | $(dirname $0)/util.js \
            >> $(dirname $0)/data/$(dirname $file | sed 's/.*\///')-address.csv
    done

find $(dirname $0)/data/ -type f -size 0 -print0 | xargs -0 rm

find $(dirname $0)/data/ -type f -regex ".*.csv" \
    | while read file; do
        sort $(dirname $0)/$file \
            | uniq > $(dirname $0)/${file}.tmp
        sed -i '1s/^/X,Y,NUM,STREET\n/' ${file}.tmp
        mv $(dirname $0)/${file}.tmp $(dirname $0)/${file}
    done

# close files
echo "]}" >> $(dirname $0)/data/parcels.geojson
