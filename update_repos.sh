#!/bin/bash
echo "${0##*/}"

# deinfe horizontal line
hline() {
    for i in {1..64}; do echo -n "-"; done
    echo
}

# list repository paths, relative to home
# scripting
list="bash \
      batch \
      powershell\
      scripts "

# settings
list+="config "

# fortran
list+="fortran \
       hello \
       nrf "

# matlab
list+="matlab \
       matlab/macros "

# projects
list+=""

loc_fail=""
pull_fail=""
push_fail=""
for repo in $list
do
    hline
    echo -e "locating $repo... \c"
    if [ -d ${HOME}/$repo ]; then
	echo "OK"
	cd ${HOME}/$repo
	#	echo -e "pulling $repo... \c"
	git pull --all
	if [[ $? != 0 ]]; then
	    echo "pull: $?"
	    pull_fail+="$repo "
	fi
	#	echo -e "pushing $repo... \c"
	git push --all
	if [[ $? != 0 ]]; then
	    echo "push: $?"
	    push_fail+="$repo "
	fi
    else
	echo "not found"
	loc_fail+="$repo "
    fi
    hline
    echo
done

if [ -z "$loc_fail" ]; then
    echo "no location fails"
else
    echo "    not found: $loc_fail"
fi

if [ -z "$push_fail" ]; then
    echo "no push fails"
else
    echo "push failures: $push_fail"
fi
if [ -z "$pull_fail" ]; then
    echo "no pull fails"
else
    echo "pull failures: $pull_fail"
fi
