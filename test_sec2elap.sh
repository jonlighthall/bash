#!/bin/bash
# program to test formatting of sec2elap over different time epochs
for n in {1..8}
do
    echo $n
    echo $((10**n))
    sec2elap $((10**$n))
done
# print time at exit
echo -e "\n$(date +"%R") ${BASH_SOURCE##*/} $(sec2elap $SECONDS)"