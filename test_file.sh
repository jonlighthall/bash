#!/bin/sh

if [ $# -eq 0 ]
then
    echo "Please provide an input file"
else
    for arg in "$@"
    do
	echo
	echo -n "$arg "
	if [ -L $arg ] ; then
	    echo "is a link"
	    echo -n " The link is... "
	    if [ -e $arg ] ; then
		echo "valid"
	    else
		echo "broken"
	    fi
	elif [ -e $arg ] ; then
	    echo "exists"
	    echo -n " It is... "
	    if [ -f $arg ]; then
		echo "a regular file"
	    else
		echo -n "not a regular file, but... "
		if [ -d $arg ]; then
		    echo "a directory"
		else
		    echo "not a directory"
		fi
	    fi	
	else
	    echo "does not exist"
	fi
    done
fi
echo
echo " " $(date) "at time $SECONDS"
