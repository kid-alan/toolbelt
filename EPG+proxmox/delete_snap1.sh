#!/bin/bash
## Delete initial state of machine (snap1)

rm /mnt/backups/varsnap1.bak
rm /mnt/backups/usrsnap1.bak
rm /mnt/backups/homesnap1.bak
lvremove -f /dev/main/rootsnap1