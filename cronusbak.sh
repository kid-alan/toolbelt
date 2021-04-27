#!/bin/bash
set -x
mkdir /aa /mnt/bak

mount /dev/sda3 /mnt/bak

mount -r /dev/md2 /aa
mount -r /dev/md0 /aa/boot
mount -r /dev/md7 /aa/home
mount -r /dev/md3 /aa/tmp
mount -r /dev/md4 /aa/var
mount -r /dev/md5 /aa/var/lib/postgresql
mount -r /dev/md6 /aa/var/log

/mnt/bak/fullbackup.sh /aa/ clean-cronus
set +x