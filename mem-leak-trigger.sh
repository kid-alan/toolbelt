#!/bin/bash
 
# Crutch by Alan
# Checks for available memory and restarts leaking services. Script is activated via cron periodically.
# Script will check if it was run in last 15 minutes and abort if it did.
# Crontab: * * * * * /home/mem-leak-trigger.sh
 
log_file="/var/log/mem-leak-trigger.log"
 
function log_msg() {
echo `date +%Y-%m-%d`" "`date +%H:%M:%S`": "$1 >> $log_file
echo $1
}
 
MEM_TRIGGER_MB=1024     # set this value in megabytes
COOLDOWN_MIN=15         # minutes to wait since last trigger activation
 
MEM_AVAIL_KB=`awk '/MemAvailable/ { print $2 }' /proc/meminfo`
let MEM_AVAIL_MB=$MEM_AVAIL_KB/1024
let MEM_AVAIL_GB=$MEM_AVAIL_MB/1024
let MEM_TRIGGER_GB=MEM_TRIGGER_MB/1024
# workaround for first run
if [[ -s /run/mem-leak-trigger.time ]] ; then
	let LASTRUN_MIN=(`date +%s`-`cat /run/mem-leak-trigger.time`)/60
else
	LASTRUN_MIN=1500000000
fi
 
# main ()
log_msg ""$MEM_AVAIL_MB"MB ("$MEM_AVAIL_GB"GB) of memory is now available."
 
if [[ $MEM_AVAIL_MB -lt $MEM_TRIGGER_MB ]] ; then
        if [[ $LASTRUN_MIN -lt $COOLDOWN_MIN ]] ; then
                log_msg "Out of memory, but script triggered less then "$COOLDOWN_MIN" minutes ago. Exiting..."
                exit 0
        else
                date +%s > /run/mem-leak-trigger.time
                log_msg "Out of memory! Trigger set for "$MEM_TRIGGER_MB"MB ("$MEM_TRIGGER_GB"GB) but only "$MEM_AVAIL_MB"MB ("$MEM_AVAIL_GB"GB) is left."
                log_msg "Restarting services:"
                log_msg "==="
                supervisorctl restart mm >> $log_file 2>&1
                supervisorctl restart mm2 >> $log_file 2>&1
                supervisorctl restart mm3 >> $log_file 2>&1
                supervisorctl restart mm4 >> $log_file 2>&1
                log_msg "==="
                log_msg "Done. Exiting..."
                exit 1
        fi
else
                log_msg "Memory is not full. Yet..."
                exit 0
fi