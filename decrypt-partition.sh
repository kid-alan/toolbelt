#!/bin/bash

# Decrypts var partition using user-supplied password, mounts it, and restores services depending on /var directory, $

cryptsetup open --type luks /dev/ALL/var var-encrypted

if [[ $? != 0 ]]; then
        echo "Something went wrong with partition decription. Partition will not be mounted. Exiting..."
        exit 1
fi

echo "Mounting partition to /var"
mount /dev/mapper/var-encrypted /var

echo "Starting system daemons"
service exim4 start
service rc.local start
service postgresql start
service redis_6379 start
service cron start
service atop start
service rsyslog start
service dm-event start

echo "Starting EPG"
service epg start
