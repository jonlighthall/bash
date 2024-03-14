#!/bin/bash -u
echo $BASH_SOURCE

fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# get list of deleted files
list=$(\ls -l | awk '{print $9}')
echo $list
echo
# checkout deleted files
for fname in $list
do
    \ls -dl $fname
    timeout -s 9 1s \ls -dl --color $fname
    RETVAL=$?
    echo -n "$fname "
    if [[ $RETVAL -eq 137 ]]; then
	echo -e "${BAD}FAIL${RESET} ${gray}RETVAL=$RETVAL${RESET}"
    else
	echo -e "${GOOD}OK${RESET} ${gray}RETVAL=$RETVAL${RESET}"
	test_file $fname
    fi
done
wait
# print time at exit
echo -e "\n$(date +"%a %b %-d %-l:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"
