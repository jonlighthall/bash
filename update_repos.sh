#!/bin/bash
echo "${0##*/}"

# deinfe horizontal line
hline() {
    for i in {1..69}; do echo -n "-"; done
    echo
}

# list repository paths, relative to home
# scripting
list="bash \
      batch \
      powershell "

# settings
list+="config \
       home "

# utilities
list+="fortran_utilities "

repo_dir="repos/"
# tutorials
list+="${repo_dir}fortran \
       ${repo_dir}hello \
       ${repo_dir}nrf \
       ${repo_dir}nrf77 \
       ${repo_dir}python "

# matlab
list+="matlab \
       matlab/macros "

# projects
list+=""

# inaccessible
#list+="scripts"

loc_fail=""
pull_fail=""
push_fail=""
mods=""
for repo in $list
do
    hline
    echo -e "locating $repo... \c"
    if [ -e ${HOME}/$repo ]; then
	echo "OK"
	cd ${HOME}/$repo
	git rev-parse --is-inside-work-tree >/dev/null 2>&1
	RETVAL=$?
	if [[ $RETVAL -eq 0 ]]; then
	    #	echo -e "pulling $repo... \c"
	    git pull --all --tags --prune
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
	    if [[ ! -z $(git ls-files -m) ]]; then
		echo "modified:"
		git ls-files -m | sed 's/^/   /'
		mods+="$repo "
	    fi
	else
	    echo "return value = $RETVAL"
	    echo "$repo not a repo"
	    loc_fail+="$repo "
	fi
    else
	echo "not found"
	loc_fail+="$repo "
	test_file ${HOME}/$repo
    fi
    hline
    echo
done

echo -n "    not found: "
if [ -z "$loc_fail" ]; then
    echo "none"
else
    echo "$loc_fail"
fi
echo -n "push failures: "
if [ -z "$push_fail" ]; then
    echo "none"
else
    echo "$push_fail"
fi
echo -n "pull failures: "
if [ -z "$pull_fail" ]; then
    echo "none"
else
    echo "$pull_fail"
fi
echo -n "     modified: "
if [ -z "$mods" ]; then
    echo "none"
else
    echo "$mods"
fi
