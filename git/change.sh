#!/bin/sh

git filter-branch --commit-filter '

WRONG_EMAIL="lighthall@2b1ce1e5-f9e2-4de2-b566-7fb11778057d"
CORRECT_NAME="Jon Lighthall"
CORRECT_EMAIL="jon.lighthall@gmail.com"

if [ "$GIT_COMMITTER_EMAIL" = "$WRONG_EMAIL" ]; then
    GIT_COMMITTER_NAME="$CORRECT_NAME"
    GIT_COMMITTER_EMAIL="$CORRECT_EMAIL"
fi
if [ "$GIT_AUTHOR_EMAIL" = "$WRONG_EMAIL" ]; then
    GIT_AUTHOR_NAME="$CORRECT_NAME"
    GIT_AUTHOR_EMAIL="$CORRECT_EMAIL"
fi
git commit-tree "$@"; 
' HEAD
