#!/bin/bash
# Alan, for CRT-28302, 30.01.2020
#
# Archives a previous day + deletes obsolete raw logs older then 'keep_days'
# 5 lines of real action wrapped with 125 lines of sanity checks...
#
# Zabbix/Exit status codes:
#   1 - Script started
#   0 - Script finished successfully
#   2 - Script finished with warning
#   3 - Script finished with error
#
# Run it every night from crontab
# 0 3 * * * /home/kmu/daily-archive.sh

keep_days=30 # Days to keep raw logs intact
logfile="/home/logserver/logserver/log/daily-archive.log"
dir="/home/logserver/logserver/media/archives"
zabbix_ip="192.168.152.4"

del_date=$(date +%Y/%m/%d --date="-$(( keep_days + 1 )) day")
del_year=$(date +%Y --date="-$(( keep_days + 1 )) day")
del_month=$(date +%m --date="-$(( keep_days + 1 )) day")
del_day=$(date +%d --date="-$(( keep_days + 1 )) day")
old_archive_name=$del_year-$del_month-$del_day.tar.gz

year=$(date +%Y --date="-1 day")
month=$(date +%m --date="-1 day")
day=$(date +%d --date="-1 day")
archive_name=$year-$month-$day.tar.gz
archive_created_flag=0

function log_msg() {
  echo "$(date +%Y-%m-%d)" "$(date +%H:%M:%S)"": ""$1" >> $logfile
  echo "$1"
}

function zbx_send() {
  zbx_key="archive.status"
  /usr/bin/zabbix_sender -z $zabbix_ip -s "Peoplemeter-Log-Server" -k $zbx_key -o $1
  case $? in
  0) log_msg "Sent \"$zbx_key $1\" to Zabbix." ;;
  *) log_msg "Tried to send \"$zbx_key $1\" to Zabbix, but failed." ;;
  esac
}

function clean_exit {
  log_msg "Attempting a clean exit"
  log_msg "Removing an unfinished $archive_name archive"
  rm $dir/$year/$month/$archive_name
  zbx_send 2
  log_msg "Exiting..."
  exit 0
}
trap 'clean_exit' INT QUIT TERM HUP

function check_archive {
if [[ -e $dir/$year/$month/$archive_name ]]; then
  log_msg "Checking content of $dir/$year/$month/$archive_name"
  tar_count=$(tar tvf "$dir/$year/$month/$archive_name" 2>> $logfile | wc -l)
  tar_count=$(( tar_count - 1 ))
  log_count=$(ls -A "$dir/$year/$month/$day" | wc -l)
  if [[ "$log_count" == "$tar_count" ]]; then
    log_msg "Archive $archive_name seems to be good. There are $log_count files in both dir and archive."
    archive_created_flag=1
    return 0
  else
    log_msg "Something seems wrong. $log_count files in dir and $tar_count files in archive."
    return 1
  fi
else
  log_msg "There is no archive for a previous day."
  return 2
fi
}

function check_old_archive {
if [[ -e $dir/$del_year/$del_month/$old_archive_name ]]; then
  log_msg "Checking content of old $dir/$del_year/$del_month/$old_archive_name"
  tar_count=$(tar tvf "$dir/$del_year/$del_month/$old_archive_name" 2>> $logfile | wc -l)
  tar_count=$(( tar_count - 1 ))
  log_count=$(ls -A "$dir/$del_year/$del_month/$del_day" | wc -l)
  if [[ "$log_count" == "$tar_count" ]]; then
    log_msg "Old archive $archive_name seems to be good. There are $log_count files in both old dir and old archive."
    return 0
  else
    log_msg "Something seems wrong. $log_count files in old dir and $tar_count files in old archive."
    return 1
  fi
else
  log_msg "There is no archive for a deletion day."
  return 2
fi
}

function create_archive {
  log_msg "DEBUG: cd $dir/$year/$month/"
  cd $dir/$year/$month/
  log_msg "DEBUG: tar czf $archive_name ./$day/ 2>&1 >> $logfile"
  tar czf $archive_name ./$day/ 2>&1 >> $logfile
  cd || return
}

function check_old_logs {
log_msg "Checking $dir/$del_date"
diff=$(( $(date +%s)-$(date +%s --date="$del_date") ))
thres=$(( 7*24*60*60 )) # Hardcoded for a reason
if [[ $diff -lt $thres ]]; then
  return 2 # weird date
elif [[ ! -d $dir/$del_date ]]; then
  return 1 # no dir
else
  return 0 # ok
fi
}

function delete_old_logs {
  log_msg "Removing the $dir/$del_date"
  rm -rf $dir/$del_date
}

### MAIN ###
log_msg "====="
log_msg "Step 1/5: Looking for an already existing archives."
zbx_send 1 ## Script started
check_archive
case $? in
  0) log_msg "Good archive already exists." ;; #continue
  1) log_msg "Check the archive manually. Exitinig..." && zbx_send 3 && exit 3 ;;
  2) log_msg "Done!" ;; #continue
  *) log_msg "Unknown error while checking archive. Exiting..." && zbx_send 3 && exit 3 ;;
esac

if [[ $archive_created_flag != 1 ]]; then
  log_msg "Step 2/5: Archiving a previous day."
  create_archive
  log_msg "Done!"
  
  log_msg "Step 3/5: Checking created archive."
  check_archive
  case $? in
    0) log_msg "Done!" ;; #continue
    1) log_msg "Check the archive manually. Exitinig..." && zbx_send 3 && exit 3 ;;
    2) log_msg "ERROR: Failed to create an archive. Exiting..." && zbx_send 3 && exit 3 ;;
    *) log_msg "Unknown error while checking archive. Exiting..." && zbx_send 3 && exit 3 ;;
  esac
  
else
log_msg "Step 2/5: Archiving a previous day - SKIPPED"
log_msg "Step 3/5: Checking created archive - SKIPPED"
fi

log_msg "Step 4/5: Preparing to delete old logs."
log_msg "Checking old logs dir."
check_old_logs
case $? in
  0) log_msg "Old logs dir is OK!" ;; #continue
  1) log_msg "WARNING: $dir/$del_date seems to be already deleted. Exiting..." && zbx_send 2 && exit 2 ;;
  2) log_msg "Script tried to delete $del_date, which is less then 7 days from today. That doesn't seems right. Check the keep_days variable and date conditions. Exiting..." && zbx_send 3 && exit 3 ;;
  *) log_msg "Unknown error while preparing to delete old logs. Exiting..." && zbx_send 3 && exit 3 ;;
esac

log_msg "Checking old archive."
check_old_archive
case $? in
  0) log_msg "Old archive is OK!" ;; #continue
  1) log_msg "Check the archive manually. Old logs are not deleted. Exitinig..." && zbx_send 3 && exit 3 ;;
  2) log_msg "ERROR: No archive for deletion date. Old logs are not deleted. Exiting..." && zbx_send 3 && exit 3 ;;
  *) log_msg "Unknown error while checking archive. Exiting..." && zbx_send 3 && exit 3 ;;
esac

log_msg "Step 5/5: Deleting old logs."
delete_old_logs
check_old_logs
case $? in
  0) log_msg "WARNING: $dir/$del_date seems to be still there. Check manually." && zbx_send 2 && exit 2;;
  1) log_msg "Done!" ;; #continue
  2) log_msg "Script tried to delete $del_date logs, which is less then 7 days from today. That doesn't seems right. Check the keep_days variable and date conditions. Exiting..." && zbx_send 3 && exit 3 ;;
  *) log_msg "Unknown error while preparing to delete old logs. Exiting..." && zbx_send 3 && exit 3 ;;
esac

zbx_send 0 ## Script succeeded
log_msg "Success! Archived all logs in $archive_name without errors."
exit 0
