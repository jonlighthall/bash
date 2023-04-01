#!/bin/bash

# set directories
export dir_common="${HOME}/utils/scripts/"
export REMOTE="jlighthall@host:${dir_common}"
export LOCAL=${dir_common}

# set command
CMD='rsync -vruth --progress'

# "pull"
SOURCE=$REMOTE
DEST=$LOCAL
test_file ${DEST}
echo "pulling files from ${SOURCE}..."
if [ $# -eq 0 ]; then
    echo "No pattern given. Coppying all."
    echo "$CMD $SOURCE* $DEST"
    $CMD $SOURCE* $DEST
else
    echo $CMD $SOURCE$1 $DEST
    $CMD $SOURCE$1 $DEST
fi

# "push"
SOURCE=$LOCAL
DEST=$REMOTE
test_file ${SOURCE}
echo "pushing files to ${DEST}..."

if [ $# -eq 0 ]; then
    echo "No pattern given. Coppying all."
    echo "$CMD $SOURCE* $DEST"
    $CMD $SOURCE* $DEST
else
    echo "$CMD $SOURCE$1 $DEST"
    $CMD $SOURCE$1 $DEST
fi
