#!/bin/bash -u
TAB="     "
echo "current author name:"
git config --get user.name | uniq | sed "s/^/${TAB}/"
echo
echo "current author email:"
git config --get user.email | uniq | sed "s/^/${TAB}/"
echo
if [ ! -z $(git rev-parse --is-inside-work-tree 2>/dev/null) ]; then
    echo "list of authors:"
    git log --all --pretty=format:"%aN %aE" | sort | uniq -c | sort -n
    echo
    echo "list of committers:"
    git log --all --pretty=format:"%cN %cE" | sort | uniq -c | sort -n
    echo
    echo "list of taggers:"
    git tag --format="%(authorname) %(authoremail)" | sort -u | sed "s/^/${TAB}/"
    echo
    echo "list of names:"
    git log --all --pretty=format:"%aN%n%cN" | sort -u | sed "s/^/${TAB}/"
    echo
    echo "list of emails:"
    git log --all --pretty=format:"%aE%n%cE" | sort -u | sed "s/^/${TAB}/"
else
    echo "$PWD is not a Git repsoitory"
fi
echo
