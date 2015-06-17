#!/usr/bin/env node
var geojsonStream = require('geojson-stream');

var inputStream = process.stdin;
var outputStream = process.stdout;

var processStream = inputStream.pipe(geojsonStream.parse());

function output(feature) {
    outputStream.write(feature.geometry.coordinates.join(',') + ',' + feature.properties.address + ',' + feature.properties.street + '\n');
}

processStream.on('data', function(feature) {
    Object.keys(feature.properties).forEach(function(prop) {
        if (prop.indexOf('PropertyAddress') !== -1 && feature.properties[prop]) {
            //There are a lot of partial addresses that this drops. they are typically in the format `11??` or `00000`
            var address = feature.properties[prop].match(/^\d+\s/);

            var street = feature.properties[prop].split(',')[0];
            if (address && !address[0].match(/^0+\s$/)) {
                feature.properties = {
                    address: address[0].trim(),
                    street: street.replace(address[0], '').trim()
                }
                output(feature)
            }
        } else if (prop.indexOf('STREETNUM') !== -1 && feature.properties[prop]){
            var address = feature.properties[prop];
            var street;

            if (feature.properties.STR_NAME) {
                street =
                    (feature.properties.PRE_DIR ? feature.properties.PRE_DIR : '') + ' ' +
                    (feature.properties.STR_NAME) +
                    (feature.properties.STR_TYPE ? feature.properties.STR_TYPE : '') +
                    (feature.properties.SUF_DIR ? feature.properties.SUF_DIR : '')
            }

            if (street && address) {
                feature.properties = {
                    address: address,
                    street: street.trim()
                }
            }
        }
    });
});

processStream.on('error', function(err) {
    console.error(err);
    process.exit(1);
});

