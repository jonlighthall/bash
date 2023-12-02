#!/bin/bash -u

# get starting time in nanoseconds
start_time=$(date +%s%N)

# set tab
TAB=${TAB:=''}

# load formatting
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# determine if script is being sourced or executed and add conditional behavior
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
    set -eE
fi

# print source name at start
echo "${TAB}${RUN_TYPE} $BASH_SOURCE..."
src_name=$(readlink -f $BASH_SOURCE)
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
    echo -e "${TAB}${VALID}link${NORMAL} -> $src_name"
fi

# define traps
trap "echo -e 'exiting...\n$(sec2elap $dT | tr -d '\n')'" EXIT

# print instructions
echo "press Ctrl-C to exit"

while [ .true ]; do
    elap_time=$(($(date +%s%N) - ${start_time}))
    dT=$(bc <<<"scale=3;$elap_time/1000000000")
    #    echo -en "\x1b[2K\relapsed time is ${white}${dT_sec} sec${NORMAL}"
    echo -en "\x1b[2K\r$(sec2elap $dT | tr -d '\n')"
    trap 'start_new_line; echo -e "breaking..."; break;' INT
done
