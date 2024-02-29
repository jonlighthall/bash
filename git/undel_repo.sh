#!/bin/bash -u
# Checks a Git repository for deleted files and restores those files
# by checking them out

# load formatting
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
    if [ -z ${fpretty_loaded+dummy} ];then
        source $fpretty
    fi
fi

# print source at start
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
    set -eE
    trap 'echo -e "${BAD}ERROR${NORMAL}: exiting ${BASH_SOURCE##*/}..."' ERR
fi
echo -e "${TAB}${RUN_TYPE} ${PSDIR}$BASH_SOURCE${NORMAL}..."
src_name=$(readlink -f $BASH_SOURCE)
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
    echo -e "${TAB}${VALID}link${NORMAL} -> $src_name"
fi

# define counters
declare -i found=0
declare -i check=0

# get list of deleted files
list=$(git ls-files -d)

# checkout deleted files
for fname in $list; do
	((++found))
    echo $fname
    git checkout $fname
	RETVAL=$?
	if [[ $RETVAL -eq 0 ]]; then
		((++check))
	fi
done
wait

echo "done"

# print summary
echo
echo -e "\E[4m${found} files found:\E[0m"
echo "${check} files restored"

# print time at exit
echo -e "\n$(date +"%a %b %-d %-l:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
