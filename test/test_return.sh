#!/bin/bash -eu

DEBUG=0

# load formatting and functions
fpretty="${HOME}/config/.bashrc_pretty"
if [ -e "${fpretty}" ]; then
    source "${fpretty}"
    print_debug
 #   set_traps
fi

# determine if script is being sourced or executed and add conditional behavior
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"

else
    RUN_TYPE="executing"
    # exit on errors

fi

get_source
echo -e "${INVERT}$src_base${NORMAL} Run type = ${RUN_TYPE}"

lecho
print_source
set -e

function cleanup () {
    echo -e "${INVERT}${FUNCNAME}${NORMAL}"
    echo "${BASH_SOURCE[0]##*/}"    
}

function do_return() {
    echo -e "${INVERT}${FUNCNAME}${NORMAL}"
    echo "${BASH_SOURCE[0]##*/}"
    print_stack
    return

}


set -e
set_traps


echo "function:"
itab
fello
dtab
echo "alias:"
itab
echo -n "${TAB}"
hello
dtab

lecho
echo "here"
#DEBUG=0
#clear_traps
trap do_return EXIT


#trap 'echo "${FUNCNAME} return"; trap -- RETURN; trap -- EXIT; trap -- ERR; set +eE' RETURN
#trap 'echo "${FUNCNAME} exit -> return"; trap -- RETURN; trap -- EXIT; trap -- ERR' EXIT
set +ET
exit_on_fail


#return && exit_on_fail
exit_on_fail
echo "there"
