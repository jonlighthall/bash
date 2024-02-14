#!/bin/bash -u
# add_path.sh - prepends arguments to PATH. Add the directories passed to the
# command as arguments to the start of the PATH environmental variable.
#
# NB: remember to 'source' this script, don't just execute it
#
# Path additions
for ADDPATH in "$@"; do
    echo -n ${ADDPATH}
# check if path exists
    if [ -d "${ADDPATH}" ]; then
        echo " found"
        ABSPATH=$(cd $ADDPATH; \pwd)
        echo -n ${ABSPATH}
    else
        echo " not found"
        continue
    fi
    # prepend path to PATH
	if [[ "$PATH" != *"${ADDPATH}:"* ]]; then
        export PATH=$ADDPATH:$PATH
        echo " added to PATH"
    else
        echo " already in PATH"
    fi
done
echo "done"

# print time at exit
echo -e "\n$(date +"%a %b %-d %-l:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
