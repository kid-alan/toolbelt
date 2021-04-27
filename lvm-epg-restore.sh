#!/bin/bash
lvconvert --merge /dev/EPG-LVM/postgresqlsnap1
lvconvert --merge /dev/EPG-LVM/varsnap1
lvconvert --merge /dev/EPG-LVM/rootsnap1
lvconvert --merge /dev/EPG-LVM/homesnap1