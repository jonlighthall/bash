#!/bin/bash -eu

# load formatting and functions
fpretty="${HOME}/config/.bashrc_pretty"
if [ -e "${fpretty}" ]; then
    source "${fpretty}"
    print_debug
        set_traps
    #set_exit
else
    # ignore undefined variables
    set +u
    # do not exit on errors
    set +e
fi

# determine if script is being sourced or executed and add conditional behavior
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
    # exit on errors
    set -e
fi
get_source
echo -e "${INVERT}$src_base${NORMAL} Run type = ${RUN_TYPE}"

lecho
print_source

fello
hello

lecho

echo "here"
exit_on_fail
