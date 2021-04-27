#!/bin/bash

# Decrypts epg partition using user-supplied password, mounts it, and restores services dependent on /var/www/EPG/ directory.
# Script could be added to ~/.profile, to execute on login

mountpoint -q /var/www/EPG/
if [[ $? = 0 ]]; then
        echo "/var/www/EPG/ is already mounted"
        exit 1
fi

echo "--------------"
echo "---Warning!---"
echo "--------------"
echo "/var/www/EPG/ partition need to be decrypted and mounted"
cryptsetup open --type luks /dev/ALL/epg epg-encrypted

if [[ $? != 0 ]]; then
        echo "Something went wrong with partition decription. Partition will not be mounted. Exiting..."
        exit 1
fi

echo "Mounting partition to /var/www/EPG/"
mount /dev/mapper/epg-encrypted /var/www/EPG

#echo "Starting system daemons"
#service exim4 start
#service rc.local start
#service postgresql start
#service redis_6379 start
#service cron start
#service atop start
#service rsyslog start
#service dm-event start
#service nfs-common start
#service atd start

echo "Starting EPG"
service epg start