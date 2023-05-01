#!/bin/bash
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
