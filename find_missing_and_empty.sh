#!/bin/bash
# reads an input list of files names. any files that are not found or empty are written to an
# output list. handling is included to backup any duplicated input/output file names.

# set file names
file_in=$1
file_out=missing.txt
base="${file_out%.*}"
ext="${file_out##*.}"
file_new=${base}_$(date +'%Y-%m-%d-t%H%M').${ext}

# initialize counters
i=0 # missing files
j=0 # empty files
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
        echo "renaming input..."
        mv -v ${file_out} ${file_new}
        file_in=${file_new}
    else
        echo "unique"
    fi

    # check if output exists
    echo -n "output file ${file_out}... "
    if [ -f ${file_out} ]; then
        echo "exists"
        echo "renaming output..."
        mv -v ${file_out} ${file_new}
    fi

    # read input file
    while read line; do
        # modify file name
        #fpre="${line%.*}"
        #fname=$(printf '%s_suf.ext' "$fpre" )
        fname=$line
        ((k++))
        # printf "%5d %s\n" $k $line
        if [ ! -f $fname ]; then
            ((i++))
            echo $i $fname "is missing"
            echo $line >> ${file_out}
        else
            if [ ! -s $fname ]; then #adding empty increases runtime < 4%
                ((j++))
                echo $j $fname "is empty"
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
# print time at exit
echo -e "\n$(date +"%a %b %-d %I:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"