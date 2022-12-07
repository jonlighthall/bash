#!/bin/bash
echo $BASH_SOURCE

  GOOD='\033[0;32m'
   BAD='\033[0;31m'
NORMAL='\033[0m'

# get list of deleted files
list=$(\ls -l | awk '{print $9}')
echo $list
echo
# checkout deleted files
for fname in $list
do
    echo $fname
    \ls -dl $fname
    timeout -s 9 1s \ls -dl --color $fname
    RETVAL=$?
    if [[ $RETVAL -eq 137 ]]; then
	echo -e "\n RETVAL = $RETVAL"
	echo -e " ls --color=auto ${BAD}timed out${NORMAL}"
    else
	echo -e "${GOOD}OK${NORMAL}"
	test_file $fname
    fi
done
wait
echo
echo "${TAB}$(date): ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
