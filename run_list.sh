#!/bin/bash
# Reads a list of input files and, if the list file exists, run the
# specified program. The first arugement is rqpured and specifies the
# run list file. An optional second argument can be used to specifed
# the program.

if [ $# -eq 0 ]
then
    echo "Please provide an input file"
else
    FILE1=$1
    if [ $# -eq 2 ]; then
	PROGRAM=$2
    else
	PROGRAM=/home/jlighthall/nspe/nspe60_Dec2018/nspe.x
	#PROGRAM=/jfs02/iampsdata/commands/nspe58/nspe.x
	#PROGRAM=/jfs02/iampsdata/commands/nspe60/nspe.x
    fi
    echo Program is $PROGRAM
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
