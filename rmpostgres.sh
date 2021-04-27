#!/bin/bash

curdir=$(pwd)
cd /var/lib/postgresql
rm -rf ./*
mklost+found
cd $curdir