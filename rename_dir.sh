#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Please provide an input directory"
    exit 1
fi

echo "number of arguments = $#"
echo "argument 1: $1"


#dir_in=$(realpath $1)
#echo -n "  input directory ${dir_in}... "
dir_in=${1%/*}


echo -n "  input directory ${dir_in}... "
if [ -d "${dir_in}" ]; then
    echo "exits"
else
    echo "does not exist"
    exit 1
fi

echo "directory name is $dir_in"




echo "directory name is ${#dir_in} long"

dir_lim=20
dir_trunc=${dir_in:0:$dir_lim}
echo "short directory name is $dir_trunc"


#find $1 -type f -printf "%p\t%TF\n"

#find $1 -type f -printf "%TF\n"
line_width=$(( $(tput cols) - 1 ))
#find $1 -type f -printf "%TF %p\n" | cut -c -$line_width

#find $1 -type f -printf "%TF  %p\n" | sort -n | cut -c -$line_width

echo

echo "dates found"
find $1 -type f -name "*ens???*??????????_nspe_??????_d????_f?????*" -printf "%TF\n" | sort -n | uniq -c



echo
echo "most common date"
find $1 -type f -name "*ens???*??????????_nspe_??????_d????_f?????*" -printf "%TF\n" | sort -n | uniq -c | head -n 1
echo


mdate=$(find $1 -type f -name "*ens???*??????????_nspe_??????_d????_f?????*" -printf "%TF\n" | sort -n | uniq -c | head -n 1 | awk '{print $2}')


echo "original directory name is $dir_in" >> ${dir_in}/readme.txt


echo $mdate

dir_out=$(echo "${mdate}_${dir_trunc}")

echo $dir_out

echo -n "  output directory ${dir_out}... "
if [ -d ${dir_out} ]; then
    echo "exits"
else
    echo "does not exist"
    mv -vn ${dir_in} ${dir_out}
    
fi
