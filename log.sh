#!/bin/bash
if [ $# -eq 0 ]
then
    echo "Please provide an executable"
else
    # trim leading dot-slash
    TRIM=$(echo $1 | sed 's:^\./::')
    echo -e "logging $TRIM... \c"
    # test command
    if ! command -v $1 &> /dev/null
    then
	echo "not found"
    else
	echo "OK"
	FNAME=${TRIM}_output_$(date +'%Y-%m-%d-t%H%M').log
	echo -e "saving to $FNAME... \c"
 	$1 2>&1 | tee ${FNAME}
#	$1 > ${FNAME} 2>&1;echo "done" 
    fi
fi