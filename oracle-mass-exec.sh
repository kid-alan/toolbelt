#!/bin/bash
 
i=0
n=`cat ./servers.list | wc -l`
logfile="./log"
 
function log_msg() {
echo `date +%Y-%m-%d`" "`date +%H:%M:%S`": "$1 >> $logfile
echo $1
}
 
echo " " >> $logfile
log_msg "======================"
log_msg "=== SCRIPT STARTED ==="
log_msg "======================"
echo " " >> $logfile
 
cat ./servers.list | while read ip
do
        let i=i+1
        echo " " >> $logfile
        log_msg "=== Starting SQL for $ip ($i/$n) ==="
        echo " " >> $logfile
        echo exit | sqlplus super/OURPASSWORD@$ip @sql.sql 2>&1 | tee -a $logfile
done