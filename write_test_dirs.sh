#!/bin/bash
# reads a list of input directories from a file and for each directory,
# if the directory exists, performs a write test of the directory
FILE1=$1

i=0
j=0

while read line; do
    printf "testing %s\n" $line
    if [ -d $line ]; then
	#echo $line "is dir"
	((i++))
	cd $line
	touch write_test.txt
	if [ -f write_test.txt ]; then
	    echo $line "write succeeded"
	    rm write_test.txt
	else
	    echo $line "write failed"
	    ((j++))
	fi
    fi
done < $FILE1
echo $i "directories checked"
echo $j "of" $i "failed write"
# print time at exit
echo -e "\n$(date +"%R") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"