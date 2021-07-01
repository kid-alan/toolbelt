#!/bin/bash
# Live root filesystem backup using LVM snapshots

date_time=`date '+%Y-%m-%d_%H-%M-%S'`
backup_root=/mnt/backups-sde/
backup_dir=$backup_root/OMV-full-backups/$date_time
log_file=$backup_root/OMV-full-backups/$date_time.log

#log {} # TODO insert a logging function
function log() {
        echo `date +%Y-%m-%d`" "`date +%H:%M:%S`": "$1 >> $log_file
        echo $1
}

cd "$(dirname "$0")" # Making sure, that working dir is at the script location

log "Checking if running root"
if [ $(whoami) == "root" ]; then
        log "OK!"
else
        log "Must be root"
        exit 1
fi

log "Checking if $backup_root is a mount point."
if mountpoint $backup_root; then
        log "OK!"
else
        log "$backup_root is not a mount point. Exiting."
        exit 1
fi

log "Checking if rsync-exclusions file exists."
if [ -s ./rsync-exclusions ]; then
        log "OK!"
else
        log "rsync-exclusions file is empty or doesn't exist. Exiting."
        exit 1
fi

log "Checking if $backup_dir exists. It should not."
if [ ! -d $backup_dir ]; then
        log "OK!"
else
        log "$backup_dir already exists. Check manually."
        exit 1
fi

log "Checking if snapshot exists. It should not."
if [ ! -e /dev/mapper/main-root--bkp--snapshot ]; then
        log "OK!"
else
        log "Snapshot already exists. Check manually."
        exit 1
fi

mkdir -p $backup_dir |& tee -a $log_file
lvcreate -v -L1G -s -n root-bkp-snapshot /dev/mapper/main-root |& tee -a $log_file
mkdir /tmp/root-bkp-snapshot |& tee -a $log_file
mount -r /dev/mapper/main-root--bkp--snapshot /tmp/root-bkp-snapshot |& tee -a $log_file
rsync --info=progress2,stats2 -aHAXS --exclude-from=./rsync-exclusions /tmp/root-bkp-snapshot/ /$backup_dir/ |& tee -a $log_file
rsync --info=progress2,stats2 -aHAXS /boot/ /$backup_dir/boot/ |& tee -a $log_file
umount /tmp/root-bkp-snapshot |& tee -a $log_file
lvremove -v -f /dev/mapper/main-root--bkp--snapshot |& tee -a $log_file
