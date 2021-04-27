#!/bin/bash
lvcreate -s -L 20G -n postgresqlsnap1 /dev/EPG-LVM/postgresql
lvcreate -s -L 50G -n varsnap1 /dev/EPG-LVM/var
lvcreate -s -L 3G -n rootsnap1 /dev/EPG-LVM/root
lvcreate -s -L 2G -n homesnap1 /dev/EPG-LVM/home