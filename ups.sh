#!/bin/bash

# Checks, if UPS is on battery, and shut down ESXi after N minutes.
# Executed by cron every minute.


log_file="/var/log/ups/ups.log"
TRIGGER_MIN=3 # trigger after this consecutive minutes of offline
ESX_IP=192.168.173.45
ESX_SH_PATH="/vmfs/volumes/datastore1/scripts/switchoff.sh"

function log_msg() {
echo `date +%Y-%m-%d`" "`date +%H:%M:%S`": "$1 >> $log_file
echo $1
}


# Minutes since last online
if [[ -s /run/ups-last-online.time ]] ; then
	let LASTOL_MIN=(`date +%s`-`cat /run/ups-last-online.time`)/60
else
	LASTOL_MIN=0 # now
fi

# Logging stats
log_msg
upsc ippon600@localhost 2>/dev/null | grep -E 'input.voltage|battery.voltage|ups.status|battery.charge' >> $log_file

if [[ $(upsc ippon600@localhost 2>/dev/null | grep ups.status | awk '{print $2}') = OL ]]; then
	date +%s > /run/ups-last-online.time
elif [[ $(upsc ippon600@localhost 2>/dev/null | grep ups.status | awk '{print $2}') != OL ]]; then
	if [[ $LASTOL_MIN -ge $COOLDOWN_MIN ]]; then
		log_msg "Detected OFFLINE! Last online was $LASTOL_MIN ago. Shutting down ESXi."
		ssh root@$ESX_IP '$ESX_SH_PATH'
		exit 1
	elif
		log_msg "Detected OFFLINE! Last online was $LASTOL_MIN ago. Waiting for $TRIGGER_MIN minutes."
		exit 0
	fi
fi
