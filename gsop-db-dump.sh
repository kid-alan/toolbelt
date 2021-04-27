#!/bin/bash
## gsop-pg-dump.sh
#
# This script makes database dump and move it to remote backup server
#
# Scripts should be executed by user postgres
# User postgres should have r/w priveleges on "working_dir" for script to work.
#
# Written by: Denis Burtsev
#

## Variables to be specified by user
db_name="database_to_backup"
backuper_ip="172.30.50.157"
working_dir="/var/backups/pg-dumps"

## Other variables
host_name=`hostname`
curr_date=`date '+%Y-%m-%d_%H-%M-%S'`
dump_name=`echo $host_name-$db_name-$curr_date.pgdmp`
dest_dir=`echo ${host_name//[^A-Z]}`
log_file="$working_dir/$db_name-pg-dump.log"
local_backup_dir="$working_dir/$db_name"

## Functions block
log_msg() {
        echo `date +%Y-%m-%d`" "`date +%H:%M:%S`": "$1 >> $log_file
        #echo $1
        }

cd ~ # Prevents erratic errors

## Creating and checking a local backup
log_msg "======="
log_msg "[INFO]: Creating a local backup \"$local_backup_dir/$dump_name\"."
mkdir -p $local_backup_dir > /dev/null 2>> log_file
pg_dump -Fc $db_name -U postgres 2>> log_file > $local_backup_dir/$dump_name
if [ -f "$local_backup_dir/$dump_name" ]; then
        log_msg "[INFO]: Local dump \"$local_backup_dir/$dump_name\" was created successfuly."
else
        log_msg "[ERROR]: Error, local dump was not created properly. Exiting..."
        exit 0
fi

## Checking for remote storage and folder availability
log_msg "[INFO]: Checking if backuper $backuper_ip is available over network."
ping -c 1 $backuper_ip > /dev/null
if [ $? -eq 0 ]; then
        log_msg "[INFO]: Backuper is available. Continuing with remote backup."
else
        log_msg "[ERROR]: No ping to backuper. Only local backup is created. Exiting..."
        exit 0
fi

log_msg "[INFO]: Checking if a remote folder \"/home/backuper/GSOP/$dest_dir/$host_name/$db_name\" exists."
if ssh backuper@$backuper_ip "[ ! -d "/home/backuper/GSOP/$dest_dir/$host_name/$db_name" ]"; then
        log_msg "[WARN]: Folder does not exist, creating."
        ssh backuper@$backuper_ip "mkdir -p /home/backuper/GSOP/$dest_dir/$host_name/$db_name" 2>> log_file
else
        log_msg "[INFO]: Folder exists, continue."
fi


## Copying dump to remote storage
log_msg "[INFO]: Copying dump to backuper."
scp -r $local_backup_dir/$dump_name backuper@$backuper_ip:/home/backuper/GSOP/$dest_dir/$host_name/$db_name 2>> log_file
sleep 5s
log_msg "[INFO]: Checking if copy \"/home/backuper/GSOP/$dest_dir/$host_name/$db_name/$dump_name\" was created succesfully."
if ssh backuper@$backuper_ip "[ -f "/home/backuper/GSOP/$dest_dir/$host_name/$db_name/$dump_name" ]"; then
        log_msg "[INFO]: Dump was copied to backuper succesfully"
else
        log_msg "[ERR]: No dump found at the at the backuper. Exiting!"
fi

log_msg "[INFO]: Finished the dumping process successfully!"
exit