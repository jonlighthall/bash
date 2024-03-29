#!/bin/bash -u
#
# untar.sh - untar archvies - why isn't this an intrinsic?
#
# May 2022 JCL

echo "${0##*/}"
if [ $# -eq 0 ]; then
    echo "Please provide a target archive"
    exit 1
else
    if [[ -f $1 ]]; then
	echo "found archive $1"
	file "${1}"
	dir_name="${1%.*}" # remove extension
        dir_name=${dir_name// /_} # remove spaces
	echo -n "target directory $dir_name... "
	if [ -d $dir_name ]; then
	    echo "found"
	else
	    echo "not found"
	    mkdir -pv ./$dir_name
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
		SUB='zip'
		if [[ "$ext_name" == *"$SUB"* ]]; then
		    echo "$1 is a zip"
		    zip -T "${1}"
		    unzip "${1}" -d $dir_name
		    exit $?
		else
		    echo "$1 file type unknown"
		    OPT=tfv
		fi
	    fi
	fi
	tar ${OPT} "${1}" -C ./$dir_name
    else
	echo "$1 is not found"
	exit 1
    fi
fi
# print time at exit
echo -e "\n$(date +"%a %b %-d %-l:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"