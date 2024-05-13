#!/bin/bash -u
hello() {
    echo "world"
}

# load formatting and functions
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
	  source $fpretty
fi

for func in hello bar hline potato
do
    echo "${TAB}testing if $func is a function"
    itab
    if [ "$(type -t $func)" != function ]; then
	      echo "${TAB}$func not a function"
        echo "${TAB}redefining $func as a no-op function"        
	      eval "$func() {
	    :
	}"
    else
	      echo "${TAB}$func is a function:"
	      $func
    fi
    dtab
done
