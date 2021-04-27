## logger
log_file="/var/log/epg/trigger.log"
function log_msg() {
echo `date +%Y-%m-%d`" "`date +%H:%M:%S`": "$1 >> $log_file
echo $1
}

## help
function help {
	echo "Usage: trigger.sh interface_name bandwidth in bytes/s"
	echo "Example: trigger.sh eth1 10000000"
	exit 0
}

## bandwidth measure
IF=eth0
while [ true ] ; do
        TX=`cat /sys/class/net/${IF}/statistics/tx_bytes`
        if [[ $TXPREV -ne -1 ]] ; then
                let BWTX=$TX-$TXPREV
                log_msg "Sent: $BWTX B/s"
        fi
        TXPREV=$TX
sleep 1
done

## IP validity
# Test an IP address for validity:
# Usage:
#      valid_ip IP_ADDRESS
#      if [[ $? -eq 0 ]]; then echo good; else echo bad; fi
#   OR
#      if valid_ip IP_ADDRESS; then echo good; else echo bad; fi
#
function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

## Scan massive with for loop
ips='
	4.2.2.2
	a.b.c.d
	192.168.1.1
	0.0.0.0
	255.255.255.255
	255.255.255.256
	192.168.0.1
	192.168.0
	1234.123.123.123
	'
for ip in $ips
do
	if valid_ip $ip; then stat='good'; else stat='bad'; fi
	printf "%-20s: %s\n" "$ip" "$stat"
done

# FOR loops
END=5
for ((i=1;i<=END;i++)); do
    echo $i
done

END=5
for i in $(seq 1 $END); do
	echo $i
done

