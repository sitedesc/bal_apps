#!/bin/bash
mysql -s -N --user=$1 --password=$2 -h $3 $4 -e "$5"