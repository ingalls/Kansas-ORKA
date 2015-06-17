# Kansas-ORKA
Download &amp; Clean Kansas ORKA data

## About

The state of Kansas provides a raster and REST endpoint to access the Open Records for Kansas Appraisers data. 

This data includes county boundaries, parcels, addresses, & some landcover data.

## Installation

- GNU coreutils
- jq, grep, sed, curl, etc.
- esri-dump (`sudo npm install -g esri-dump`)

## Running

`./get.sh` will parse the web portal and download all the available data
A cached copy of this data can be found in `data/`.

`./get.sh skip` will skip already downloaded files

-----

`./process.sh` will take the downloaded data and generate a parcel, road and address layer.
