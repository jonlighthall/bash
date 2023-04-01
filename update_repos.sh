#!/bin/bash
echo "${0##*/}"

# deinfe horizontal line
hline() {
    for i in {1..69}; do echo -n "-"; done
    echo
}

# list repository paths, relative to home
# settings
list+="config \
       home "

# scripting utilities
dir_script="utils/"
list="${dir_script}bash \
      ${dir_script}batch \
      ${dir_script}scripts \
      ${dir_script}powershell "

# programming utilities
dir_prog="utils/"
list+="${dir_prog}fortran_utilities "

# tutorial examples
dir_examp="examples/"
list+="${dir_examp}cpp \
       ${dir_examp}hello \
       ${dir_examp}fortran \
       ${dir_examp}nrf \
       ${dir_examp}nrf77 \
       ${dir_examp}python "

# matlab
dir_matlab="matlab/"
list+="${dir_matlab} \
       ${dir_matlab}macros "

# private
if [ -f private.lst ]; then
    while IFS= read -r line
    do list+=" $line"
    done < private.lst
fi

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
