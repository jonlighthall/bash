#!/bin/bash
while read -r line; do
    echo "$line"
    ts1=$(echo $line | awk '{print $1}')
    echo "timestamp = $ts1"
    if [ $ts1 = $ts2 ]; then
        echo "match"
    else
        echo "new"
        ts2=${ts1}
        echo $line | awk '{print $2}' >>good_hashes.txt
    fi
done <hash_list2.txt
