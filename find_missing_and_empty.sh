#!/bin/bash
# reads a list of input files and if the 02.asc file does not exist or is empty
# writes the name of the input file to missing.lst
FILE1=$1

i=0
j=0
k=0

if [ $# -eq 0 ]
then
    echo "Please provide an input file"
else
    if [ $FILE1 == missing.lst ]; then
	cp missing.lst missing.bak
	FILE1=missing.bak
    fi
    if [ -f missing.lst ]; then
	rm missing.lst
    fi
    while read line; do
	fpre="${line%.*}"
	fname=$(printf '%s_02.asc' "$fpre" )
	((k++))
#printf "%5d %s\n" $k $line
	if [ ! -f $fname ]; then
	    ((i++))
    #echo $i $fname "is missing"
	    echo $line >> missing.lst
	else
	    if [ ! -s $fname ]; then #adding empty increases runtime < 4%
		((j++))
      #echo $j $fname "is empty"
		echo $line >> missing.lst
	    fi
	fi
    done < $FILE1
    echo $k "filenames checked"
    echo $i "of" $k "files missing"
    ((m=k-i))
    if [ $m == 0 ]; then
	echo "no empty files found"
    else
	echo $m "files found"
	echo $j "of" $m "files empty"
    fi
    ((l=i+j))
    echo $l "of" $k "problem files"
#if [ -f missing.lst ]; then
  #cat missing.lst
#fi
fi
printf "\a"