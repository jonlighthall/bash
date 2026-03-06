#!/bin/bash -u
source ~/utils/bash/progress_report.sh
i=0
max=500
while [ $i -lt $max ]; do
    ((i++))
    progress_report $i $max
done
