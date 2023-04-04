#!/bin/bash
#
# find_matching.sh - Reads an input list of files name patterns. Any files matching the
# individual patterns are saved to a new list of file names. handling is included to backup any
# duplicated input/output file names.
#
# Adapted from find_missing_and_empty.sh
#
#JCL Apr 2023

# set file names
file_in=$1
fname=found.txt
base="${fname%.*}"
ext="${fname##*.}"
file_out=${base}_$(date +'%Y-%m-%d-t%H%M%S').${ext}

# initialize counters
k=0 # files in list

# check for input
if [ $# -eq 0 ]
then
    echo "Please provide an input file"
    exit 1
else
    # check if input and output are the same file
    echo -n "input file ${file_in} is... "
    if [ ${file_in} -ef ${file_out} ]; then
        echo "the same file as ${file_out}"
	echo "waiting..."
	sleep 1
        echo "renaming output..."
	file_out=${base}_$(date +'%Y-%m-%d-t%H%M%S').${ext}
    else
        echo "unique"
    fi

    # check if output exists
    echo -n "output file ${file_out}... "
    if [ -f ${file_out} ]; then
        echo "exists"
	echo "waiting..."
	sleep 1
        echo "renaming output..."
	file_out=${base}_$(date +'%Y-%m-%d-t%H%M%S').${ext}

    fi

    # read input file
    while read line; do
        # modify file name
        #fpre="${line%.*}"
        #fname=$(printf '%s_suf.ext' "$fpre" )
        fname=$line
        ((k++))
        # printf "%5d %s\n" $k $line
	echo "looking for ${fname}..."
	find ./ -name *${fname}* >> ${file_out}
        if [ ! -f $fname ]; then
            ((i++))
            echo $i $fname "is missing"
            echo $line >> ${file_out}
        else
            if [ ! -s $fname ]; then #adding empty increases runtime < 4%
                ((j++))
                echo $j $fname "is empty"
                echo $line >> ${file_out}
	    else
		echo "$k $fname is found"
		echo $line >> ${file_out}
            fi
        fi
    done < $file_in
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
    #if [ -f ${file_out} ]; then
    #cat ${file_out}
    #fi
fi
printf "\a"
