#!/bin/bash
if [ $# -eq 0 ]
then
    echo "Please provide two input files"
else
    echo "First arg: $1"
    echo "Second arg: $2"
    if [ ! -f $1 ]; then
	echo "file $1 does not exist. creating..."
	touch $1
    fi
    cp -v $1 copy1
    if [ ! -f $2 ]; then
	echo "file $2 does not exist. creating..."
	touch $2
    fi
    cp -v $2 copy2
fi