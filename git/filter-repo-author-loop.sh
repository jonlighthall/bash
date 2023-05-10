set -e
# print source name at start
echo -n "source: $BASH_SOURCE"
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

for branch in $branch_list
do
    git checkout $branch
    git fetch ${name_remote} ${branch}
    git log ${name_remote}/${branch} --pretty=format:"%aN %aE" | sort | uniq -c | sort -n
    git diff ${branch} ${name_remote}/${branch}

    N=$(git log ${name_remote}/${branch} --pretty=format:"%aN %aE" | sort -u | wc -l)
    if [ $N -gt 1 ]; then
	echo "${TAB}more than one author on remote branch ${name_remote}/${branch} (N=$N)"
	echo "filtering repo and force pushing..."
	filter-repo-author.sh $@
	echo "done filtering repo."
	echo "force pushing rewrite..."
	git push -f ${name_remote} ${branch}
    else
	echo "${TAB}only one author on remote branch ${name_remote}/${branch}!"
	echo "no need to force push"
	git log --pretty=format:"%aN %aE" | sort | uniq -c | sort -n
	M=$(git log --pretty=format:"%aN %aE" | sort -u | wc -l)
	if [ $M -gt 1 ]; then
	    echo "more than one author on local branch ${branch} (M=$M)"
	    ehco "force pull..."
	    force_pull
	else
	    echo "${TAB}only one author on local branch ${branch}!"
	    echo "no need to force pull"
	fi

	if [ N==1 ] && [ M==1 ] && [ -z "$(git diff ${branch} ${name_remote}/${branch})" ]; then
	    echo "only one author on local and remote"
	    echo "no differences between local and remote" 
	    echo "reseting HEAD to ${name_remote}/${branch}..."
	    git reset ${name_remote}/${branch}
	    git pull ${name_remote} ${branch}
	    git push ${name_remote}
	    if [ -z "$(git branch -vv | grep \* | grep "\[")" ]; then
		echo "no remote tracking branch"
		git branch --set-upstream-to=${name_remote}/${branch} ${branch}
	    fi
	else
	    echo "unsafe to reset"
	    echo "remote authors N=$N"
	    echo " local authors M=$M"
	fi
    fi
done
echo "done"
echo "switching back to ${branch_local}..."
git checkout ${branch_local}
