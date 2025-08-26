#!/bin/bash -u

# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

echo "current author name:"
git config --get user.name | uniq | sed "s/^/${TAB}/"
echo
echo "current author email:"
git config --get user.email | uniq | sed "s/^/${TAB}/"

function print_auth() {
    echo
    echo "-----------------------------------------------"
    echo -e "$@"

    # strip color
    local arg
    arg=$(echo "$@" | sed -r "s/\\\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g")

    # check if argument is empty
    if [ -z "$arg" ]; then
        echo "${TAB}no branch specified"
        return
    fi

    if [ ! -z $(git rev-parse --is-inside-work-tree 2>/dev/null) ]; then
        (
            echo "list of authors:"
            git log "$arg" --pretty=format:"%aN %aE" | sort | uniq -c | sort -n
            echo
            echo "list of names:"
            git log "$arg" --pretty=format:"%aN" | sort -u | sed "s/^/${TAB}/"
            echo
            echo "list of emails:"
            git log "$arg" --pretty=format:"%aE" | sort -u | sed "s/^/${TAB}/"
        ) | sed "s/^/${TAB}/"
    else
        echo "$PWD is not a Git repsoitory"
    fi
#    echo
}

print_auth --all

current_branch=$(git branch | grep "^*" | sed "s/* //")
print_auth ${GOOD}${current_branch}${RESET}

git rev-parse --abbrev-ref @{upstream} &>/dev/null
RETVAL=$?
if [[ $RETVAL -ne 0 ]]; then
    do_cmd git rev-parse --abbrev-ref @{upstream}
    echo "no remote tracking branch set for current branch"
else
    remote_tracking_branch=$(git rev-parse --abbrev-ref @{upstream})
    print_auth ${ARG}${remote_tracking_branch}${RESET}
fi
