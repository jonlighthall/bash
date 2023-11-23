#!/bin/bash

start_time=$(date +%s%N)
# set tab
TAB=${TAB:=''}

# load formatting
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# print source name at start
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
fi
echo "${TAB}${RUN_TYPE} $BASH_SOURCE..."
src_name=$(readlink -f $BASH_SOURCE)
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
    echo -e "${TAB}${VALID}link${NORMAL} -> $src_name"
fi
echo "press Ctrl-C to exit"
while [ .true ]; do
    elap_time=$(($(date +%s%N) - ${start_time}))
    dT=$(bc <<<"scale=3;$elap_time/1000000000")
    chmod -Rc 777 /home/jlighthall/.vscode-server/
    trap 'echo -e "\nbreaking..."; break;' INT
done
trap "echo -e 'exiting...\n$(sec2elap $dT)'" EXIT
