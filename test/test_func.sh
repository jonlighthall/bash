#!/bin/bash -u
hello() {
    echo "world"
}

for func in hello bar hline potato
do
    echo "testing if $func is a function"
    if [ "$(type -t $func)" != function ]; then
	echo "$func not a function"
	eval "$func() {
	    :
	}"
    else
	echo "$func is a function:"
	$func
    fi

done
