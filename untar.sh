#!/bin/bash
#
# untar.sh - untar archvies - why isn't this an intrinsic?
#
# JCL May 2022

echo "${0##*/}"
if [ $# -eq 0 ]; then
    echo "Please provide a target archive"
    exit 1
else
    if [[ -f $1 ]]; then
	echo "found archive $1"

	dir_name="${1%.*}"
	echo -n "target directory $dir_name... "
	if [ -d $dir_name ]; then
	    echo "found"
	else
	    echo "not found"
	fi
	ext_name="${1##*.}"
	echo "extension is $ext_name"

	SUB='tar'
	if [[ "$ext_name" == *"$SUB"* ]]; then
	    echo "$1 is a tarball"
	    OPT=xfv
	else
	    SUB='tgz'
	    if [[ "$ext_name" == *"$SUB"* ]]; then
		echo "$1 is a gzip"
		OPT=xfvz
	    else
		echo "$1 file type unknown"
		OPT=tfv
	    fi
	fi
	mkdir -pv ./$dir_name
	tar ${OPT} $1 -C ./$dir_name
    else
	echo "$1 is not found"
	exit 1
    fi
fi
