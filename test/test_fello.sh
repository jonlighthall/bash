#!/bin/bash
DEBUG=${DEBUG:-2}
VB=${VB:-false}

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
print_source
vecho "loading .bash_aliases..."
source "$HOME/config/.bash_aliases"

echo "here"
# determine if script is being sourced or executed
if (return 0 2>/dev/null); then
    fello
else
    echo -e "${BAD}${BASH_SOURCE##*/} must be sourced${RESET}"
fi
echo "there"
unset_traps
