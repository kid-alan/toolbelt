#!/bin/bash

workdir="/var/log/epg/capture-output"
logfile="$workdir/capture.log"

function log_msg() {
echo `date +%Y-%m-%d`" "`date +%H:%M:%S`": "$1 >> $logfile
echo $1
}

function increment_minute_count() {
n_minute=$(( n_minute + 1 ))
echo $n_minute > $workdir/n_minute.state
}

function reset_minute_count() {
n_minute=0
echo $n_minute > $workdir/n_minute.state
}

function clean_exit() {
increment_minute_count
kill $tsudprecieve_pid > /dev/null 2>&1
log_msg "Exiting..."
exit 1
}

trap 'clean_exit' INT QUIT TERM HUP

log_msg "Capture-output started"
log_msg "Workdir is $workdir"
log_msg "Logfile is $logfile"

mkdir $workdir/current-capture $workdir/to-archive-tmp $workdir/archived > /dev/null 2>&1

# Check and load state
if [[ -s $workdir/n_minute.state ]]; then
	n_minute=$(cat $workdir/n_minute.state)
else
	echo "0" > $workdir/n_minute.state
fi

while : ; do
	date_time=$(date +%Y-%m-%d)"_"$(date +%H-%M-%S)
	log_msg "Capturing $date_time.ts..."
	timeout 1m tsudpreceive 239.2.2.2 1245 > $workdir/current-capture/$date_time.ts &
	tsudprecieve_pid=$!
	sleep 60

# Log results
	if ! [[ -e $workdir/current-capture/$date_time.ts ]]; then
	log_msg "File $date_time.ts wasn't captured (doesn't exist). Something went wrong. Exiting."
	clean_exit

	elif [[ -s $workdir/current-capture/$date_time.ts ]]; then
#	file-size=$(du -h ./capture-output.sh | cut -f1)
	log_msg "Successfully captured $date_time.ts with size $(du -h $workdir/current-capture/$date_time.ts | cut -f1)."

	elif [[ $(du $workdir/current-capture/$date_time.ts) -eq 0 ]]; then
	log_msg "Capture file $date_time.ts is empty. Check broadcasting state."
	fi

increment_minute_count

	if [[ n_minute -ge 30 ]]; then
	log_msg "Captured $n_minute files."

	log_msg "Moving to temp folder $workdir/to-archive-tmp/"
	mv $workdir/current-capture/*.ts $workdir/to-archive-tmp/

	log_msg "Archiving to $workdir/archived/$date_time.tar.gz"
	cur_dir=$pwd
	cd $workdir/to-archive-tmp
	nice -n 5 tar --remove-files -zcf $workdir/archived/$date_time.tar.gz ./* &
	cd $cur_dir
	reset_minute_count
	fi
done
