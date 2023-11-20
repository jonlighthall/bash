# load formatting
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
	source $fpretty
fi

# print source name at start
if (return 0 2>/dev/null); then
	RUN_TYPE="sourcing"
else
	RUN_TYPE="executing"
	set -e
fi
echo -e "${TAB}${RUN_TYPE} ${PSDIR}$BASH_SOURCE${NORMAL}..."
src_name=$(readlink -f $BASH_SOURCE)
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
	echo -e "${TAB}${VALID}link${NORMAL} -> $src_name"
fi

# parse remote
if [ -z "$(git branch -vv | grep \* | grep "\[")" ]; then
	echo "no remote tracking branch set for current branch"
else
	branch_tracking=$(git branch -vv | grep \* | sed 's/^.*\[//;s/\(]\|:\).*$//')
	echo -e "remote tracking branch is ${blue}${branch_tracking}${NORMAL}"
	name_remote=${branch_tracking%%/*}
	echo "remote is name $name_remote"
	url_remote=$(git remote -v | grep ${name_remote} | awk '{print $2}' | sort -u)
	echo "remote url is ${url_remote}"
	# parse branches
	branch_remote=${branch_tracking#*/}
	echo "remote branch is $branch_remote"
fi
branch_local=$(git branch | grep \* | sed 's/^\* //')
echo -e " local branch is ${green}${branch_local}${NORMAL}"

branch_list=$(git branch -va | sed 's/^*/ /' | awk '{print $1}' | sed 's|remotes/.*/||' | sort -u | sed '/HEAD/d')
echo "list of branches: "
echo "${branch_list}" | sed 's/^/   /'

# stash local changes
if [ -z "$(git diff)" ]; then
	echo "no differences to stash"
	b_stash=false
else
	git status
	echo "stashing differences..."
	git stash
	b_stash=true
fi

for branch in $branch_list; do
	bar 56 "$(git checkout $branch 2>&1)"
	git fetch ${name_remote} ${branch}
	git --no-pager diff --name-only ${branch} ${name_remote}/${branch}

	# determine number of authors on remote branch
	echo "remote:"
	git log ${name_remote}/${branch} --pretty=format:"%aN %aE" | sort | uniq -c | sort -n
	N=$(git log ${name_remote}/${branch} --pretty=format:"%aN %aE" | sort -u | wc -l)
	if [ $N -gt 1 ]; then
		echo "${TAB}${GRH}more than one author on remote branch ${name_remote}/${branch} (N=$N)${NORMAL}"
		echo "${TAB}filtering repo..."
		${HOME}/utils/bash/git/filter-repo-author.sh $@
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

			ver=$(git --version | awk '{print $3}')
			ver_maj=$(echo $ver | awk -F. '{print $1}')
			ver_min=$(echo $ver | awk -F. '{print $2}')
			ver_pat=$(echo $ver | awk -F. '{print $3}')

			# determine number commits local branch is behind remote
			if [ $ver_maj -lt 2 ]; then
				echo "pulling commits"
				git pull ${name_remote} ${branch}
			else
				if [ -z $(git rev-list --left-only ${name_remote}/${branch}...${branch}) ]; then
					echo "no commits to pull"
				else
					echo "pulling commits"
					git pull ${name_remote} ${branch}
				fi
			fi

			# determine number commits local branch is ahead of remote
			if [ $ver_maj -lt 2 ]; then
				echo "pushing commits"
				git push ${name_remote}
				if [ -z $(git rev-list --right-only ${name_remote}/${branch}...${branch}) ]; then
					echo "no commits to push"
				else
					echo "pushing commits"
					git push ${name_remote}
				fi
			fi

			# determine difference between local and remote
			if [ -z "$(git diff ${branch} ${name_remote}/${branch})" ]; then
				echo "no differences between local and remote"

				hash_remote=$(git rev-parse ${name_remote}/${branch})
				hash_local=$(git rev-parse HEAD)
				echo -n "${TAB}local and remote hashes..."
				if [[ "$hash_remote" == "$hash_local" ]]; then
					echo -e "${GOOD}match${NORMAL}"
				else
					echo -e "${BAD}no not match${NORMAL}"
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
bar 56 "$(git checkout ${branch_local} 2>&1)"
if $b_stash; then
	git stash pop
fi
