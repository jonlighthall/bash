#!/bin/bash -u
i=0
while [ $i -lt 5 ]; do
    ((i++))
    echo "$i"
done
