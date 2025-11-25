#!/bin/bash -u
#
# log.sh - copy STDOUT and STDERR to log file with date

if [ $# -eq 0 ]; then
    echo "Please provide an executable"
else
    # trim leading dot-slash
    TRIM="${1#./}"
    echo -e "logging $TRIM... \c"
    # test command
    if ! command -v $1 &>/dev/null; then
        echo "not found"
    else
        echo "OK"
        LOGDIR=./log
        FNAME=$LOGDIR/${TRIM}_output_$(date +'%Y-%m-%d-t%H%M').log
        mkdir -p $LOGDIR
        echo -e "saving to $FNAME..."
        $1 2>&1 | tee ${FNAME}
        echo "done"
    fi
fi
