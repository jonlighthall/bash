#!/bin/bash -ue
DUMMY=dummy
fname=parent.sh
if [ -f $fname ]; then
    echo -e "\n\E[7mexecute ${fname} in subshell:\E[0m"
    ./$fname
    echo -e "\n\E[7source ${fname} in same shell:\E[0m"
    . "$fname"
    echo -e "\n\E[7${SHELL} ${fname}:\E[0m"
    $SHELL $fname
fi
