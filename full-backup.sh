#!/bin/bash
# Fully backups system to 116 storage

#set -x		#Debug

SRC_PATH=$1
BACKUP_NAME=$2
FULL_BACKUP_NAME="$BACKUP_NAME"_$(date +"%d-%m-%Y_%H-%M")
DEST_PATH=/run/user/1000/gvfs/smb-share:server=10.243.56.175,share=manual-backups/anka/$FULL_BACKUP_NAME/

echo "Backing up $SRC_PATH"
echo "Backup label is \"$BACKUP_NAME\""
echo "Backing up to $DEST_PATH"

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
- /home/ania/Downloads/*
" > /tmp/exclude
## End of Exclude file


rsync -qaHAXS -cz --delete --info=progress2 --exclude-from=/tmp/exclude $SRC_PATH $DEST_PATH

#set +x		#Debug
