#!/bin/bash
# set paths
source rpath.sh
SOURCE=${REMOTE%/}
DEST=${LOCAL%/}

# set command
CMD='rsync -vihtu --progress'

# set copy pattern
if [ $# -eq 0 ]; then
    echo "No pattern given. Coppying all."
    PAT=''
else
    PAT="$1"
fi

# pull
echo "pulling remote changes..."
echo "$CMD $SOURCE/$PAT $DEST/"
$CMD $SOURCE/$PAT $DEST/
