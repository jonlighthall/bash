#!/bin/bash
export FILTER_BRANCH_SQUELCH_WARNING=1
rm -rdv ./.git-rewrite

git filter-branch $1 --env-filter '
WRONG_EMAILS="lighthall@lsu.eud \
              jlighthall@fsu.edu"
WRONG_EMAIL+=" jonathan.lighthall@"
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
