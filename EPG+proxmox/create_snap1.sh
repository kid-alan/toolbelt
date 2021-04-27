#!/bin/bash
## Save initial state of machine (snap1)
#set -x

if [ -e /dev/main/rootsnap1 ]
  then
	echo "Root snapshot already exists, exiting"
	exit 0
fi

du --max-depth=1 / > /mnt/backups/sh/du-snap1.txt 2> /dev/null

lvcreate -s -L 1G -n rootsnap1 /dev/main/root

function snapdump {
# Create snapshot, mount it ro, dump to backups, remove snapshot
# Example:
# snapdump var snap1

LV_NAME=$1
SNAP_NAME=$LV_NAME$2

echo "Dumping LV /dev/main/$LV_NAME"
echo "tmp snapshot name: $SNAP_NAME"

#set -x
lvcreate -s -L 5G -n $SNAP_NAME /dev/main/$LV_NAME
mkdir /mnt/$SNAP_NAME
mount -r /dev/main/$SNAP_NAME /mnt/$SNAP_NAME
dump -0 -u -f /mnt/backups/$SNAP_NAME.bak /mnt/$SNAP_NAME
umount /mnt/$SNAP_NAME
rmdir /mnt/$SNAP_NAME
lvremove -f /dev/main/$SNAP_NAME
#set +x

unset LV_NAME SNAP_NAME
}

snapdump var snap1
snapdump usr snap1
snapdump home snap1

#set +x