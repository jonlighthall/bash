#!/bin/bash
source rpath.sh
SOURCE=$REMOTE
DEST=$LOCAL
CMD='rsync -vihtu --progress'
if [ $# -eq 0 ]; then
    echo "No pattern given. Coppying all."
    echo "$CMD $SOURCE* $DEST"
    $CMD $SOURCE* $DEST
else
    echo $CMD $SOURCE$1 $DEST
    $CMD $SOURCE$1 $DEST
fi
