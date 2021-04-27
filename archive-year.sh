#!/bin/bash
# Alan, for CRT-28302, 30.01.2020
#
# Archives a chosen peoplemeter year IN A SINGLE RUN, day-by-day.
# rm -rf part is commented by default, so you won't do damage. Uncomment when sure.
# You can safely stop and re-run again - it will continue where it stopped.
#
# Example of running in background:
# nohup /home/kmu/archive-year.sh 2018 >/dev/null 2>&1 &


if [[ $1 != 2016 && $1 != 2017 && $1 != 2018 && $1 != 2019 ]] ; then
    echo "Need a year 2016..2019 as an argument"
    exit 1
fi

year=$1
month=""
day=""
logfile="/home/logserver/logserver/log/archive-$year.log"
dir="/home/logserver/logserver/media/archives"

function log_msg() {
echo "$(date +%Y-%m-%d)" "$(date +%H:%M:%S)"": ""$1" >> $logfile
echo "$1"
}

function clean_exit {
  log_msg "Attempting a clean exit"
  rm "$year-$month-$day.tar.gz"
  log_msg "Removed an unfinished $year-$month-$day.tar.gz archive"
  log_msg "Exiting..."
  exit 0
}

trap 'clean_exit' INT QUIT TERM HUP

echo " " >> $logfile
log_msg "=== SCRIPT STARTED ==="
echo " " >> $logfile

for i in {0..364}; do
  month=$(date +%m --date="$year-01-01 +$i day")
  day=$(date +%d --date="$year-01-01 +$i day")

  if [[ -e $dir/$year/$month/$day ]]; then
    [[ $(pwd) != "$dir/$year/$month" ]] && cd "$dir/$year/$month" && log_msg "Changed dir to $dir/$year/$month"
    if [[ -e "$year-$month-$day.tar.gz" ]]; then
      log_msg "$year-$month-$day.tar.gz already exist."
      log_msg "Moving to the next day..."
    else
      log_count=$(ls -A ./$day/ | wc -l)
      if [[ $log_count -lt 100 ]]; then
        log_msg "Only $log_count files found in the /$year/$month/$day. That is suspicilosly low."
        log_msg "Moving to the next day..."
      else
        log_msg "Creating a $year-$month-$day.tar.gz..."
        log_msg "Executing: tar czf $year-$month-$day.tar.gz ./$day/ >> $logfile" 2>&1
        tar czf $year-$month-$day.tar.gz ./$day/ >> $logfile 2>&1

        log_msg "Comparing file count in dir ./$day/ and $year-$month-$day.tar.gz..."
        tar_count=$(( $(tar tvf $year-$month-$day.tar.gz | wc -l) - 1 ))
        if [[ "$log_count" == "$tar_count" ]]; then
          log_msg "Everything seems fine. There are $log_count files in both dir and archive."
        else
          log_msg "Something seems wrong. $log_count files in dir ./$day/ and $tar_count files in $year-$month-$day.tar.gz. Exiting..."
          exit 0
        fi

        log_msg "Deleting the source dir /$year/$month/$day ..."
        log_msg "Executing: rm -rf ./$day 2>&1 >> $logfile"
        #rm -rf ./$day 2>&1 >> $logfile
        log_msg "Success!"
      fi
    fi
  else
    log_msg "Dir $dir/$year/$month/$day not found. Moving to the next day..."
  fi
done;