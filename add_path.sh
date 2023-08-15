#!/bin/bash
# add the directories passed to the command as arguments to the start
# of the PATH environmental variable
#
# NB: remember to 'source' this script, don't just execute it
#
# Path additions
for ADDPATH in "$@"
do
    echo -n ${ADDPATH}
    if [ -d "${ADDPATH}" ] ; then
	echo " found"
	ABSPATH=$(cd $ADDPATH; \pwd)
	echo -n ${ABSPATH}
    else
	echo " not found"
    fi
    if [[ "$PATH" != *"${ABSPATH}:"*  ]]; then
	export PATH=$ABSPATH:$PATH
	echo " added to PATH"
    else
	echo " already in PATH"
    fi
done
echo "done"
# print time at exit
echo -e "\n$(date +"%a %b %-d %-l:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"