#!/bin/bash
# Fully backups system to 116 storage

#set -x		#Debug

SRC_PATH=$1
BACKUP_NAME=$2
DEST_PATH=root@10.128.64.116:/rsync/"$BACKUP_NAME"_$(date +"%d-%m-%Y_%H-%M")/

echo "Backuping $SRC_PATH"
echo "Backup label is \"$BACKUP_NAME\""
echo "Backuping to $DEST_PATH"

## Exclude file
echo -e "
- /dev/*
- /dvd/*
- /lost+found/*
- /media/*
- /mnt/*
- /proc/*
- /sys/*
- /tmp/*
" > /tmp/exclude
## End of Exclude file


rsync -qaHAXS -cz --delete --info=progress2 --exclude-from=/tmp/exclude $SRC_PATH $DEST_PATH

#set +x		#Debug
