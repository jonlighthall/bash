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

pat='^[0-9]{4}-[0-9]{2}-[0-9]{2}.*'
echo $dir_in
echo $pat
if [[ ${dir_in} =~ $pat ]]; then
    echo "date"
    in_date=${dir_in:0:10}
    echo "date is ${in_date}"
    name_in=${dir_in:10}
    # remove leading underscore
    name_in=${name_in#_}
    echo "name is $name_in"
else
    echo "no date"
    in_date=
    name_in=${dir_in}
fi

unset dir_out
unset cdate
unset mdate

# print dates
echo "file modification dates:"
find $1 -not -path "*/.git*/*" -type f -printf "%TF\n" | sort -n | uniq -c 2>&1

# find most common date
echo
echo "most common dates:"
find $1 -not -path "*/.git*/*" -type f -printf "%TF\n" | sort -n | uniq -c | sort -n -k1 -r
echo

cdate=$(find $1 -not -path "*/.git*/*" -type f -printf "%TF\n" | sort -n | uniq -c | sort -n -k1 -r | head -n 1 | awk '{print $2}')
echo "most common date: $cdate"
dir_out=${cdate}_${name_in}

if [[ "${dir_in}" == "${dir_out}" ]]; then
    echo "   no change"
else
    echo "   mv ${dir_in} ${dir_out}"
fi

# find newest date
echo
echo "newest dates:"
find $1 -not -path "*/.git*/*" -type f -printf "%TF\n" | sort -n -r | uniq -c
echo
mdate=$(find $1 -not -path "*/.git*/*" -type f -printf "%TF\n" | sort -n -r | head -n 1)
echo "newest date: $mdate"
dir_out=${mdate}_${name_in} 
if [[ "${dir_in}" == "${dir_out}" ]]; then
    echo "   no change"
else
    echo "   mv ${dir_in} ${mdate}_${name_in}"
#    mv ${dir_in} ${mdate}_${name_in}
fi
