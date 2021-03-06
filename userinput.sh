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
    if [ ! -f $2 ]; then
	echo "file $2 does not exist. creating..."
	touch $2
    fi
    read -p "Proceed with copy? (y/n) " -n 1 -r

    if [[ $REPLY =~ ^[Yy]$ ]]
    then
	echo -e '\ncopying...'
	cp -v $1 copy1
	cp -v $2 copy2
    else
	echo -e '\nexiting...'
    fi
fi