#!/bin/bash

# Usage bitrate-trigger.sh interface_name bandwith in bytes/s
# Example of putting in background:
# nohup nice -n -15 ./bitrate-trigger.sh eth1 6250000 2>&1 >/dev/null &

#work_dir='./'
#now=$(date +%Y-%m-%d)
log_file="/var/log/epg/trigger-"$1".log"

function help {
	echo "Usage: bitrate-trigger.sh interface_name bandwidth in bytes/s"
	echo "Example: bitrate-trigger.sh eth1 6250000"
	echo "Example of putting in background:"
	echo "nohup nice -n -15 ./bitrate-trigger.sh eth1 6250000 >/dev/null 2>&1 &"
	exit 0
}
function log_msg() {
echo `date +%Y-%m-%d`" "`date +%H:%M:%S`": "$1 >> $log_file
echo $1
}

if [ $# -ne 2 ]
  then
    echo "Error! Wrong amount of arguments"
    help
fi

#cd $work_dir

IF=$1
TXPREV=-1
TRIGGER_ACTIVE=true # set to false for log only
TRIGGER_BW=$2 # bandwith trigger, bytes/s
TRIGGER_T=3 # consequitive seconds of overflow to trigger
T=0

# Check if interface exists
if [ ! -e /sys/class/net/$IF ];
  then
	log_msg "Error! No such interface as \"$IF\""
	log_msg "Exiting..."
	exit 0
fi


log_msg "Application started"
log_msg "Monitoring interface $IF. Trigger set to $TRIGGER_BW bytes/s"
while [ true ] ; do
        TX=`cat /sys/class/net/${IF}/statistics/tx_bytes`
        if [[ $TXPREV -ne -1 ]] ; then
                let BWTX=$TX-$TXPREV
                log_msg "Sent: $BWTX B/s"
        fi
        TXPREV=$TX

        if [[ $BWTX -ge $TRIGGER_BW ]] ; then
                let T=T+1
                log_msg "BW overflow for $T seconds"
        elif [[ $BWTX -lt $TRIGGER_BW ]] ; then
                T=0
        fi

        if [[ $T = $TRIGGER_T && $TRIGGER_ACTIVE = true ]] ; then
                log_msg "BW overflow trigger, blocking tx UDP on $IF!"
                log_msg "iptables -I OUTPUT -o $IF -p udp -j DROP"
                iptables -I OUTPUT -o $IF -p udp -j DROP
                exit 1
        fi
sleep 1
done
