#!/bin/bash -u

# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# print source name at start
if ! (return 0 2>/dev/null); then
    set -eE
    trap 'echo -e "${BAD}ERROR${RESET}: exiting ${BASH_SOURCE##*/}..."' ERR
fi
print_source

# parse remote
if [ -z "$(git branch -vv | grep \* | grep "\[")" ]; then
    echo "no remote tracking branch set for current branch"
else
    branch_tracking=$(git branch -vv | grep \* | sed 's/^.*\[//;s/\(]\|:\).*$//')
    echo -e "remote tracking branch is ${BLUE}${branch_tracking}${RESET}"
    name_remote=${branch_tracking%%/*}
    echo "remote is name $name_remote"
    url_remote=$(git remote -v | grep ${name_remote} | awk '{print $2}' | sort -u)
    echo "remote url is ${url_remote}"
    # parse branches
    branch_remote=${branch_tracking#*/}
    echo "remote branch is $branch_remote"
fi
branch_local=$(git branch | grep \* | sed 's/^\* //')
echo -e " local branch is ${GREEN}${branch_local}${RESET}"

branch_list=$(git branch -va | sed 's/^*/ /' | awk '{print $1}' | sed 's|remotes/.*/||' | sort -u | sed '/HEAD/d')
echo "list of branches: "
echo "${branch_list}" | sed 's/^/   /'

export FILTER_BRANCH_SQUELCH_WARNING=1
if [ -f ./.git-rewirte ]; then
    rm -rdv ./.git-rewrite
fi

git filter-branch $@ --env-filter '
WRONG_EMAILS="lighthall@lsu.edu \
              jlighthall@fsu.edu \
	      jonathan.lighthall@ \
	      jonathan.c.lighthall@"
CORRECT_NAME="Jon Lighthall"
CORRECT_EMAIL="jon.lighthall@gmail.com"

for EMAIL in $WRONG_EMAILS
do
    if [ "$GIT_AUTHOR_EMAIL" = "$EMAIL" ]; then
        GIT_AUTHOR_NAME="$CORRECT_NAME"
        GIT_AUTHOR_EMAIL="$CORRECT_EMAIL"
    fi
done
' --tag-name-filter cat -- --branches --tags
