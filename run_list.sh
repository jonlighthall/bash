#!/bin/bash
# reads a list of input files and if the file exists run the specified
# program 
FILE1=$1
PROGRAM=/home/jlighthall/nspe/nspe60_Dec2018/nspe.x

if [ $# -eq 0 ]
then
    echo "Please provide an input file"
else
while read line; do
    printf "testing %s\n" $line
    if [ -f $line ]; then
	echo $line "is dir"
	cd $line
	 $PROGRAM $line
	echo $line "is clean"
    else
	echo $line " failed"
    fi
done < $FILE1
fi