#!/bin/sh

    echo
    echo -n "$1 "
    if [ -L $1 ] ; then
	echo "is already a link"
	echo -n " The link is... "
	if [ -e $1 ] ; then
	    echo "valid"
	else
	    echo "broken"
	fi
    elif [ -e $1 ] ; then
	echo "exists"
	    echo -n " It is... "
	if [ -f $1 ]; then
	    echo "a regular file"
	else
	    echo -n "not a regular file, but... "
	    if [ -d $1 ]; then
		echo "a directory"
	    else
		echo "not a directory"
	    fi
	fi	
    else
	echo "does not exist"
    fi

