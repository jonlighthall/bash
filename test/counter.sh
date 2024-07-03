#!/bin/bash -u
echo "start"
for ((n=0;n<10;n++)); do
    echo -en "\E[1K\r$n"
    sleep 0.05
done
echo
echo "done"
