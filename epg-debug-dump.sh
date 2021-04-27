#!/bin/bash

dumpname="CRT-7721"
dumpname="$dumpname"_`date +%Y-%m-%d`_`date +%H-%M`

echo $dumpname

mkdir -p /tmp/"$dumpname"/logs
mkdir -p /tmp/"$dumpname"/streams

cp -r /var/log/epg/* /tmp/"$dumpname"/logs/
cp -r /var/www/EPG/streams/* /tmp/"$dumpname"/streams