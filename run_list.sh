#!/bin/bash
# reads a list of input files and if the file exists run the specified
# program 

FILE1=$1
PROGRAM=/home/jlighthall/nspe/nspe60_Dec2018/nspe.x
#PROGRAM=/jfs02/iampsdata/commands/nspe58/nspe.x
#PROGRAM=/jfs02/iampsdata/commands/nspe60/nspe.x

if [ $# -eq 0 ]
then
    echo "Please provide an input file"
else
    while read line; do
	printf "testing %s..." $line
	if [ -f $line ]; then
	    echo " exists"
	    $PROGRAM $line &
	    echo $line "has been run"
	else
	    echo " not found"
	fi
    done < $FILE1
fi
echo " " $(date) "at time $SECONDS"
