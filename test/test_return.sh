#!/bin/bash -eu

DEBUG=0

# load formatting and functions
fpretty="${HOME}/config/.bashrc_pretty"
if [ -e "${fpretty}" ]; then
    source "${fpretty}"
    clear_traps
fi

# determine if script is being sourced or executed and add conditional behavior
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
    #enable_exit_on_fail
else
    RUN_TYPE="executing"
    set_traps
fi
print_source

# exit on errors
set -e

echo "function:"
itab
# this line will cause error if not sourced
fello

dtab
echo "alias:"
itab
echo -n "${TAB}"
hello
dtab
lecho -e "${GOOD}here${RESET}"
huh
exit_on_fail
lecho -e "${BAD}there${RESET}"
