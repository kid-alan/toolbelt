#!/bin/bash

# Author: Alan
# Service checks for HASP availability. Runs every minute with help of cron.
# If EPG is run and HASP is removeed, service should stop.
# If after removal HASP is returned, service will NOT start automatically, to prevent situations,
# when service was shut down manually for maitenance purposes.

log_file="/var/log/epg/check-aladdin.log"

function log_msg() {
echo `date +%Y-%m-%d`" "`date +%H:%M:%S`": "$1 >> $log_file
echo $1
}

if [ $(lsusb | grep -i aladdin | wc -c) -eq 0 ]; then
        log_msg "Aladdin key is disconnected from the system!"
        epg_procs=`ps aux | grep celery | grep epg | wc -l`
        if [ $epg_procs -gt 0 ]; then
                log_msg "Aladdin is disconnected and EPG seems to be on. Turning service off..."
                /etc/init.d/epg stop
                exit 1
        elif [ $epg_procs -eq 0 ]; then
                log_msg "Aladdin is disconnected and EPG seems to be off. Idling..."
                exit 0
        fi
elif [ $(lsusb | grep -i hasp | wc -c) -gt 0 ]; then
        log_msg "Aladdin key is connected to the system."
        epg_procs=`ps aux | grep celery | grep epg | wc -l`
        if [ $epg_procs -eq 0 ]; then
                log_msg "Aladdin is connected and EPG seems to be off. Idling..."
#               /etc/init.d/epg start
                exit 2
        elif [ $epg_procs -gt 0 ]; then
                log_msg "Aladdin is connected and EPG seems to be on. Idling..."
                exit 0
        fi
fi
