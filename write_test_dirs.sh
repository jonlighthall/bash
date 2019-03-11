#!/bin/bash
# reads a list of input directories and if the directory exists
# cleans the directory of unneeded NSPE files
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