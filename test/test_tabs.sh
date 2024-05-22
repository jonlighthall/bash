#!/bin/bash -eu
# get starting time in nanoseconds
start_time=$(date +%s%N)

DEBUG=${DEBUG:-0}

# load bash utilities
fpretty="${HOME}/config/.bashrc_pretty"
if [ -e "$fpretty" ]; then
    source "$fpretty"
    set_traps
fi

# determine if script is being sourced or executed
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
    # exit on errors
    set -e
fi
print_tab
print_source
print_tab

print_shlvl
set_tab_shell
print_tab
unset_traps
set_exit
