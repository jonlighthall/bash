#!/bin/bash

dnow=$(date +%s)
fname=$1
dfile=$(date +%s -r $fname)
age=$(($dnow - $dfile))
hage="$(sec2elap $age)"

echo -e "$1\t$hage"
