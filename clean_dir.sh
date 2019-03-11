#!/bin/bash
# reads a list of input directories and if the directory exists
# cleans the directory of unneeded NSPE files
FILE1=$1

while read line; do
    printf "testing %s\n" $line
    if [ -d $line ]; then
	echo $line "is dir"
	cd $line
	/home/jlighthall/local/clean_nspe.sh
	echo $line "is clean"
    else
	echo $line " failed"
    fi
done < $FILE1
