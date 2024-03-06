#!/bin/bash -u

# get starting time in nanoseconds
start_time=$(date +%s%N)

# set tab
TAB=${TAB:=''}

# load formatting
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
	# set debug level
	declare -i DEBUG=0
	set_traps
fi

# determine if script is being sourced or executed
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

# define trap
trap 'print_int; echo " breaking..."; break;' INT

# print instructions
echo "press Ctrl-C to exit"
while [ .true ]; do
    chmod -Rc 777 /home/jlighthall/.vscode-server/
done
