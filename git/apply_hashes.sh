#!/bin/bash
unset n
while read -r line
do
    echo "$line"
    git cherry-pick $line
    retval=$?
    sed -i "1,1 d" good_hashes.txt
    : $((n++))
    echo -n "   $n: "
    if [ $retval -ne 0 ]; then
	echo "FAIL"
	exit
    else
	echo "OK"
    fi
done < good_hashes.txt
