#!/bin/bash
source $1/.profile >> $3 2>&1
source $1/.bashrc >> $3 2>&1
pushd $2
bal run >> $3 2>&1
