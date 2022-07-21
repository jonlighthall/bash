#!/bin/bash
# add the following directories to the start of PATH
#
# NB: remember to 'source' this script, don't just execute it
#
# Path additions
for ADDPATH in \
    ${PWD%/*}/ \
    ${PWD%/*/*}/
do
    echo -n ${ADDPATH}
    if [[ "$PATH" != *"${ADDPATH}:"*  ]]; then
	if [ -d "${ADDPATH}" ] ; then
	    export PATH=$ADDPATH:$PATH
	    echo " added to PATH"
	else
	    echo " not found"
	fi
    else
	echo " already in PATH"
    fi
done
echo "done"
