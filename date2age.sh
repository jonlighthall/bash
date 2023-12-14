#!/bin/bash -u
if [ $# -eq 0 ]; then
	echo "Please provide an input file"
	exit 1
fi
echo "now is $(date)"
declare -i A=$(date +%s)
echo "age is $A"
echo "file date is $(date -r "$1")"
declare -i B=$(date -r $1 +%s)
echo "file age is $B"
declare -i C=$(( A - B ))
echo -n "file age is $C seconds or "
sec2elap $C 

