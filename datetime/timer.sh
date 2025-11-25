#!/bin/bash -u

# get starting time in nanoseconds
start_time=$(date +%s%N)

# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source "$fpretty"
	# set debug level
	declare -i DEBUG=0
	set_traps
fi

# determine if script is being sourced or executed and add conditional behavior
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
    set -eE
fi

print_source

# define trap
trap 'print_int; echo " breaking..."; break;' INT

# print instructions
echo "press Ctrl-C to exit"
while [ .true ]; do
	echo -en "\E[2K\r$(print_elap)"
done
