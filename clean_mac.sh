#!/bin/bash
# this script remvoes all proprietary Mac OS files from a specified directory
#
# enter the command to be applied to each file within the parenthesis
# on the next line
CMD=(rm -rvfd)
FNDCMD=(-exec ${CMD[@]} {} \;)

if [ $# -eq 0 ]; then
    echo "Please provide a target directory"
    exit 1
else
    if [[ -d $1 ]]; then
	echo "cleaning $1 ..."
        # trim target directory name
	TRIM=$(echo $1 | sed 's:/*$::')
        # trime script name
	bname=$(basename $BASH_SOURCE)
	fname=${bname%.*}
	# create log file to save errors
	error_file=$TRIM/${fname}_errors_$(date +'%Y-%m-%d-t%H%M').log

	# empty
	echo -n "  removing empty files in ${1} ..."
	find $1 -type f -not -name ".gitkeep" \
	     -not -name $error_file \
	     -empty "${FNDCMD[@]}" 2>$error_file
	find $1 -type d -empty "${FNDCMD[@]}" 2>$error_file
	echo "done"

	# OS X binaries
	echo -n "  removing OS X files in ${1} ..."
	for pe_file in \
  	    .DS_Store \
	    ._.DS_Store \
	    \.*\.swo \
	    \.*\.swp \
	    fld3c \
	    \._*
	do
	    find $1 -type f -name "${pe_file}" "${FNDCMD[@]}" 2>$error_file
	    echo -n "."
	done
	echo "done"

	# compiled files
	echo -n "  removing compiled binaries in ${1} ..."
	for pe_file in \
	    .exe \
	    .mod \
	    .o \
	    .obj \
	    .out
	do
	    find $1 -type f -name "*${pe_file}" -print0 | perl -lne "print if not -T" | xargs -0 -r "${CMD[@]}" 2>$error_file
	    echo -n "."
	done
	echo "done"
	
	# check for errors
	if [[ -f $error_file ]]; then
	    if [[ -s $error_file ]]; then
		echo "errors found"
		ls $error_file
		cat $error_file
	    else
		rm $error_file
	    fi
	else
	    echo "no errors found"
	fi
	echo "done"
    else
	echo "$1 is not found"
	exit 1
    fi
fi
# print time at exit
echo -e "\n$(date +"%R) ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"