#!/bin/bash -u
# set paths
source rpath.sh
SOURCE=${LOCAL%/}
DEST=${REMOTE%/}

# set command
CMD='rsync -vihtu --progress'

# set copy pattern
if [ $# -eq 0 ]; then
    echo "No pattern given. Coppying all."
    PAT=''
else
    PAT="$1"
fi

# push
echo "pushing local changes..."
echo "$CMD $SOURCE/$PAT $DEST/"
$CMD $SOURCE/$PAT $DEST/
