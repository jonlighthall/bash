#!/bin/sh 
#
# Purpose:
# this script iteratively compares bash history files and determines
# which files are redundant and can be deleted
#
# Dependencies:
# this scrip assumes a cron job of the folling form is active
# 0 0 * * 1 cp ~/.bash_history ~/.bash_history_$(date +'\%Y-\%m-\%d')
#
# Dec 2021 JCL
fname=hist_list.txt
find ${HOME} -maxdepth 1 -type f -name ".bash_history_*" | sort -n > $fname
N=$(wc -l < $fname)

echo "$N history files found"
echo "$((N-1)) history files will be assessed for deletion"

for ((i=1; i<$N; i++)); do
    old=$(sed ''$i'!d' $fname)
    new=$(sed ''$((i+1))'!d' $fname)
    bad=$(diff --speed-large-files --suppress-common-lines -y $old $new | grep -v ">" | wc -l)
    echo -n "$i: "
    if [ $bad -ne 0 ]; then
	echo " $old must be merged manually"
#	echo " $bad non-update differences"
else
	echo " $old is contained within $new"
	echo " $old can be deleted"
#	good=$(diff --speed-large-files --suppress-common-lines -y $old $new | grep ">" | wc -l)
#	echo " $good update-only differences in $new"
	rm -v $old
    fi
done

if [  -f $fname ]; then
    echo "$fname has $N lines"
    rm -v $fname
fi
# print time at exit
echo -e "\n$(date +"%a %b %-d %-l:%M %p %Z") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"