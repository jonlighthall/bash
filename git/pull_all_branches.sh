set -e
# print source name at start
echo -n "${TAB}running $BASH_SOURCE"
src_name=$(readlink -f $BASH_SOURCE)
if [ "$BASH_SOURCE" = "$src_name" ]; then
    echo
else
    echo " -> $src_name"
fi

# source formatting
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# parse remote
if [ -z "$(git branch -vv | grep \* | grep "\[")" ]; then
    echo "no remote tracking branch"
    exit 1
else
    branch_tracking=$(git branch -vv | grep \* | sed 's/^.*\[//;s/\(]\|:\).*$//')
    echo -e "remote tracking branch is ${blue}${branch_tracking}${NORMAL}"
    name_remote=${branch_tracking%%/*}
    echo "remote is name $name_remote"
    url_remote=$(git remote -v | grep ${name_remote} |  awk '{print $2}' | sort -u)
    echo "remote url is ${url_remote}"
    # parse branches
    branch_remote=${branch_tracking#*/}
    echo "remote branch is $branch_remote"
fi
branch_local=$(git branch | grep \* | sed 's/^\* //')
echo -e " local branch is ${green}${branch_local}${NORMAL}"

branch_list=$(git branch -va | sed 's/^*/ /' |  awk '{print $1}' | sed 's|remotes/.*/||' | sort -u | sed '/HEAD/d')
echo "list of branches: "
echo "${branch_list}" | sed 's/^/   /'

if [ -z "$(git diff)" ]; then
    echo "no differences to stash"
    b_stash=false
else
    git stash
    b_stash=true
fi

for branch in $branch_list
do
    git checkout $branch
    git fetch ${name_remote} ${branch}
    git diff ${branch} ${name_remote}/${branch}

# determine latest common local commit, based on commit message
tracking==${name_remote}/${branch_remote}
while [ -z ${hash_local} ]; do
    echo "pulling from ${tracking}"
    subj_remote=$(git log ${tracking} --format=%s -n 1)
    time_remote=$(git log ${tracking} --format=%at -n 1)
    echo "${TAB}remote commit subject: $subj_remote"

    hash_local=$(git log | grep -B4 "$subj_remote" | head -n 1 | awk '{print $2}')

    hash_local_t=$(git log --format="%at %H " | grep "$time_remote" | awk '{print $2}')

    echo "subject and time hashes..."
    if [ "$hash_local" == "$hash_local_t" ]; then
	echo "match"
    else
	echo "do not match"
	echo $hash_local
	echo $hash_local_t
	exit 1
    fi
    echo -n "${TAB}corresponding local commit hash: "
    if [ ! -z ${hash_local} ]; then
	echo "$hash_local"
	echo -n "${TAB}trailing local commits: "
	hash_start=$(git rev-list $hash_local..HEAD | tail -n 1)
	if [ ! -z ${hash_start} ]; then
	    echo
	    git rev-list $hash_local..HEAD | sed "s/^/${TAB}/"
	    N_local=$(git rev-list $hash_local..HEAD | wc -l)
	    if [ $N_local -gt 1 ]; then
		echo -n "or ${hash_start}^.."
		hash_end=$(git rev-list $hash_local..HEAD | head -n 1)
		echo ${hash_end}
	    else
		hash_end=$hash_start
	    fi
	    echo "${TAB}local branch is $N_local commits ahead of remote"
	else
	    echo "none"
	    N_local=0
	fi
    else
	echo "not found"
    fi
    tracking="${tracking}~"
done

# determine local commits not found on remote
hash_remote=$(git log ${branch_pull} | grep -B4 "${subj_remote}" | head -n 1 | awk '{print $2}')
echo -n "${TAB}corresponding remote commit hash: "
echo $hash_remote
echo -n "common commit has... "
if [ $hash_local == $hash_remote ]; then
    echo "the same hash"
    git merge-base ${branch_local} ${branch_pull}
    hash_merge=$(git merge-base ${branch_local} ${branch_pull})
    echo -n "common hash is... "
    if [ $hash_local == $hash_merge ]; then
	echo "the same as merge base"
    else
	echo "not the same as merge base"
    fi
else
    echo "a different hash (diverged)"
fi

# determine remote commits not found locally
echo -n "${TAB}leading remote commits: "
hash_start_remote=$(git rev-list $hash_remote..${branch_pull} | tail -n 1)
if [ ! -z ${hash_start_remote} ]; then
    echo
    git rev-list $hash_remote..${branch_pull} | sed "s/^/${TAB}/"
    N_remote=$(git rev-list $hash_remote..${branch_pull} | wc -l)
    if [ $N_remote -gt 1 ]; then
	echo -n "or ${hash_start_remote}^.."
	hash_end_remote=$(git rev-list $hash_remote..${branch_pull} | head -n 1)
	echo ${hash_end_remote}
    else
	hash_end_remote=$hash_start_remote
    fi
    echo "${TAB}remote branch is $N_remote commits ahead of local"
else
    echo "none"
    N_remote=0
fi

# dummy loop to match formatting
for i in 1;
do
    # determine number of authors on remote branch
    echo "remote:"
    git log ${name_remote}/${branch} --pretty=format:"%aN %aE" | sort | uniq -c | sort -n
    N=$(git log ${name_remote}/${branch} --pretty=format:"%aN %aE" | sort -u | wc -l)
    if [ $N -gt 1 ]; then
	echo "${TAB}more than one author on remote branch ${name_remote}/${branch} (N=$N)"
	echo "${TAB}filtering repo..."
	filter-repo-author.sh $@
	echo "${TAB}done filtering repo"
	echo "${TAB}force pushing rewrite..."
	git push -f ${name_remote} ${branch}
    else
	echo "${TAB}only one author on remote branch ${name_remote}/${branch}!"
	echo "${TAB}no need to filter or (force) push"
	# determine number of authors on local branch
	echo "local:"
	git log --pretty=format:"%aN %aE" | sort | uniq -c | sort -n
	M=$(git log --pretty=format:"%aN %aE" | sort -u | wc -l)
	if [ $M -gt 1 ]; then
	    echo "${TAB}more than one author on local branch ${branch} (M=$M)"
	    ehco "${TAB}force pull..."
	    force_pull
	else
	    echo "${TAB}only one author on local branch ${branch}!"
	    echo "${TAB}no need to force pull"
	fi

	if [ N==1 ] && [ M==1 ]; then
	    echo "only one author on local and remote"

	    # determine remote tracking branch
	    if [ -z "$(git branch -vv | grep \* | grep "\[")" ]; then
		echo "no remote tracking branch"
		git branch --set-upstream-to=${name_remote}/${branch} ${branch}
	    fi

	    # determine number commits local branch is behind remote
	    if [ -z $(git rev-list --left-only ${name_remote}/${branch}...${branch}) ]; then
		echo "no commits to pull"
	    else
		echo "pulling commits"
		git pull ${name_remote} ${branch}
	    fi

	    # determine number commits local branch is ahead of remote
	    if [ -z $(git rev-list --right-only ${name_remote}/${branch}...${branch}) ]; then
		echo "no commits to push"
	    else
		echo "pushing commits"
		git push ${name_remote}
	    fi

	    # determine difference between local and remote
	    if [ -z "$(git diff ${branch} ${name_remote}/${branch})" ]; then
		echo "no differences between local and remote"

		hash_remote=$(git rev-parse ${name_remote}/${branch})
		hash_local= $(git rev-parse HEAD)
		echo -n "${TAB}local and remote hashes..."
		if [[ "$hash_remote" == "$hash_local" ]]; then
		    echo "${GOOD}match${NORMAL}"
		else
		    echo "${BAD}no not match${NORMAL}"
		    echo $hash_local
		    echo $hash_remote
		    
		    echo "reseting HEAD to ${name_remote}/${branch}..."
		    git reset ${name_remote}/${branch}
		fi
	    else
		echo "unsafe to reset"
	    fi
	else
	    echo "remote authors N=$N"
	    echo " local authors M=$M"
	fi
    fi
done
echo "done"
echo "switching back to ${branch_local}..."
git checkout ${branch_local}
if $b_stash; then
    git stash pop
fi
