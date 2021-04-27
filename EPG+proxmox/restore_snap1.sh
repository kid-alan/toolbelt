#!/bin/bash
## Restore initial state (snap1)
#set -x

## Checks prerequisites
if [ ! -e /dev/main/rootsnap1 ]
  then
	echo "There is no root snapshot, exiting"
	exit 0
elif [ ! -e /mnt/backups/varsnap1.bak ]
  then
	echo "There is no varsnap1.bak, exiting"
	exit 0
elif [ ! -e /mnt/backups/usrsnap1.bak ]
  then
	echo "There is no usrsnap1.bak, exiting"
	exit 0
elif [ ! -e /mnt/backups/homesnap1.bak ]
  then
	echo "There is no homesnap1.bak, exiting"
	exit 0
elif [ ! -e /mnt/backups/sh/interfaces.prod ]
  then
	echo "There is no interfaces.prod, exiting"
	exit 0
fi



function restore_bak {
RESTORE_DIR=$1
BAK_PATH=$2

echo "Restoring $RESTORE_DIR from $BAK_PATH"

curdir=$(pwd)
cd $RESTORE_DIR
rm -rf ./*
restore -rf $BAK_PATH
rm restoresymtable
cd $curdir

unset RESTORE_DIR BAK_PATH
}

curdir=$(pwd)
cd /var/lib/postgresql
rm -rf ./*
mklost+found
cd $curdir

restore_bak /var/ /mnt/backups/varsnap1.bak
restore_bak /usr/ /mnt/backups/usrsnap1.bak
restore_bak /home/ /mnt/backups/homesnap1.bak

## Restore production IP on snap1
mkdir /mnt/rootsnap1
mount /dev/main/rootsnap1 /mnt/rootsnap1
mv /mnt/rootsnap1/etc/network/interfaces /mnt/rootsnap1/etc/network/interfaces.bak
cp /mnt/backups/sh/interfaces.prod /mnt/rootsnap1/etc/network/interfaces
sync
umount /dev/main/rootsnap1

lvconvert --merge /dev/main/rootsnap1

echo Reboot system to restore root snapshot
#set +x