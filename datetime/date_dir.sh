#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Please provide an input directory"
    exit 1
fi

# parse inputs
echo "number of arguments = $#"
echo "argument 1: $1"

# get directory name
dir_in=${1%/*}
echo -n "  input directory ${dir_in}... "

# check directory
if [ -d "${dir_in}" ]; then
    echo "exits"
else
    echo "does not exist"
    exit 1
fi
echo "directory name is $dir_in"
echo "directory name is ${#dir_in} long"

# print dates
echo "data file modification dates:"
find $1 -not -path "*/.git*/*" -type f -printf "%TF\n" | sort -n | uniq -c 2>&1

# find most common date
echo
echo -e -n "most common date:\n    "
find $1 -not -path "*/.git*/*" -type f -printf "%TF\n" | sort -n | uniq -c
echo

# find newest date
echo
echo -e -n "newest date:\n    "
find $1 -not -path "*/.git*/*" -type f -printf "%TF\n" | sort -n -k 2| uniq -c

mdate=$(find $1 -not -path "*/.git*/*" -type f -printf "%TF\n" | sort -n | uniq -c | head -n 1 | awk '{print $2}')
echo $mdate
