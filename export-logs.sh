#!/bin/bash
# Use: 'export-logs.sh serial start_date end_date CRT-12345'. Date format YYYY/MM/DD.

serial=$1
start_date=$2
end_date=$3
CRT=$4

function clean_exit {
  rm -rf /home/kmu/$CRT
  echo "Exiting..."
  exit 0
}
trap 'clean_exit' INT QUIT TERM HUP

if [ "$#" -ne 4 ]; then
  echo "Use: 'export-logs.sh serial start_date end_date CRT-12345'. Date format YYYY/MM/DD."
  echo "You must pass 4 arguments, not $#"
  exit 1
fi

if ! date --date="$start_date" > /dev/null; then
  echo "Wrong start date format. Exiting."
  exit 1
fi

if ! date --date="$end_date"> /dev/null; then
  echo "Wrong end date format. Exiting."
  exit 1
fi

diff=$(( $(date +%s --date "$start_date")-$(date +%s --date="$end_date") ))
if [[ "$diff" -gt 0 ]]; then
  echo "Start date should be earlier or equal to end date"
  exit 1
fi

curr_date_path=$(date +%Y/%m/%d --date="$start_date")
end_date_path=$(date +%Y/%m/%d --date="$end_date + 1 day") # +1 day to include the end_date

# Copy and count logs
log_count=0
mkdir /home/kmu/$CRT
while [[ $curr_date_path != $end_date_path ]]; do
  if [[ -d "/home/logserver/logserver/media/archives/$curr_date_path" ]]; then
    i=$(find /home/logserver/logserver/media/archives/$curr_date_path -name "*$serial*" -exec cp {} /home/kmu/$CRT \; -exec echo {} \; | wc -l)
    log_count=$(( $log_count+$i ))
	echo "$i logs found in /home/logserver/logserver/media/archives/$curr_date_path"
    curr_date_path=$(date +%Y/%m/%d --date="$curr_date_path + 1 day")
  else
    echo "/home/logserver/logserver/media/archives/$curr_date_path is already archived."
	archive="/home/logserver/logserver/media/archives/$(date +%Y/%m --date="$curr_date_path")/$(date +%Y-%m-%d --date="$curr_date_path").tar.gz"
	echo "Scanning $archive"
	i=$(tar -xvzf "$archive" -C /home/kmu/$CRT --wildcards --no-anchored "*$serial*" --strip-components=2 2>/dev/null | wc -l)
	log_count=$(( $log_count+$i ))
	echo "$i logs found in $archive"
    curr_date_path=$(date +%Y/%m/%d --date="$curr_date_path + 1 day")
  fi
done

echo "$log_count logs found in total"
if [[ $log_count -eq 0 ]]; then
  echo "Nothing to export. Exiting."
  rm -rf /home/kmu/$CRT
  exit 1
fi

# Archive
filename=$CRT-$serial-$(date +%d.%m.%Y --date="$start_date")-$(date +%d.%m.%Y --date="$end_date").tar.gz
cd /home/kmu/
tar -czf $filename ./$CRT
rm -rf ./$CRT
echo "Done. Archive: /home/kmu/$filename"
