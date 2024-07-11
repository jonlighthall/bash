#!/bin/bash -u

# load bash utilities
fpretty="${HOME}/config/.bashrc_pretty"
if [ -e "$fpretty" ]; then
    source "$fpretty"
fi

function test_lineno() {
    # print file line
    echo "${TAB}in function:"
    itab
    this_line "7/4: "
    echo "${TAB}8/5: LINENO = $LINENO"
    dtab
}

echo "${TAB}in script:"
itab
echo "${TAB}14: LINENO = $LINENO"
dtab
test_lineno
