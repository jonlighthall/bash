#/bin/bash
# git/force_pull.sh - the remote name and branch can be optionally specified by the first and
# second arguments, respectively. The default remote tracking branch is origin/master.

# Apr 2023 JCL

# exit on errors
set -e

# set tab
TAB=''
TAB+=${TAB+${fTAB:='   '}}

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
    remote_tracking_branch=$(git branch -vv | grep \* | sed 's/^.*\[//;s/\(]\|:\).*$//')
    echo -e "remote tracking branch is ${blue}${remote_tracking_branch}${NORMAL}"
    name_remote=${remote_tracking_branch%%/*}
    echo "remote is name $name_remote"
    url_remote=$(git remote -v | grep ${name_remote} |  awk '{print $2}' | sort -u)
    echo "remote url is ${url_remote}"
    # parse branches
    branch_remote=${remote_tracking_branch#*/}
    echo "remote branch is $branch_remote"
fi
branch_local=$(git branch | grep \* | sed 's/^\* //')
echo -e " local branch is ${green}${branch_local}${NORMAL}"

# parse arguments
if [ $# -ge 1 ]; then
    name_remote=$1
else
    echo "no remote specified"
    echo "${fTAB}using $name_remote"
fi
if [ $# -ge 2 ]; then
    branch_remote=$2
else
    echo "no remote branch specified"
    echo "${fTAB}using $branch_remote"
fi
branch_pull=${name_remote}/${branch_remote}
if [ -z ${name_remote} ] || [ -z ${branch_remote} ]; then
    echo -e "${BROKEN}ERROR: no remote tracking branch specified${NORMAL}"
    echo " HELP: specify remote tracking branch with"
    echo "       ${TAB}${BASH_SOURCE##*/} <repository> <refspec>"
    exit 1
else
    echo "comparing local branch $branch_local with remote branch $branch_pull"
fi

echo -n "pull branch and remote tracking branch... "
if [ "$branch_pull" == "$remote_tracking_branch" ]; then
    echo "match"
else
    echo "do not match"
fi

# before starting, fetch remote
echo "fetching ${name_remote}..."
git fetch ${name_remote}

# determine latest common local commit, based on commit time
iHEAD=${branch_pull}
while [ -z ${hash_local} ]; do
    echo "checking ${iHEAD}..."
    subj_remote=$(git log ${iHEAD} --format=%s -n 1)
    time_remote=$(git log ${iHEAD} --format=%at -n 1)
    echo "${TAB}remote commit subject: $subj_remote"
    echo "${TAB}remote commit time: $time_remote"

    hash_local_s=$(git log | grep -B4 "$subj_remote" | head -n 1 | awk '{print $2}')
    hash_local=$(git log --format="%at %H " | grep "$time_remote" | awk '{print $2}')

    echo -n "${TAB}subject and time hashes..."
    if [ "$hash_local" == "$hash_local_s" ]; then
	echo "match"
    else
	echo "do not match"
	echo "${TAB}subj = $hash_local_s"
	echo "${TAB}time = $hash_local"
    fi
    echo -n "${TAB}corresponding local commit hash: "
    if [ ! -z ${hash_local} ]; then
	TAB+=${fTAB:='   '}
	echo "$hash_local"
        # determine local commits not found on remote
	echo -n "${TAB}trailing local commits: "
	hash_start=$(git rev-list $hash_local..HEAD | tail -n 1)
	if [ ! -z ${hash_start} ]; then
	    echo
	    git rev-list $hash_local..HEAD | sed "s/^/${TAB}/"
	    N_local=$(git rev-list $hash_local..HEAD | wc -l)
	    if [ $N_local -gt 1 ]; then
		echo -n "${TAB}or ${hash_start}^.."
		hash_end=$(git rev-list $hash_local..HEAD | head -n 1)
		echo ${hash_end}
	    else
		hash_end=$hash_start
	    fi
	    echo -e "${TAB}${yellow}local branch is $N_local commits ahead of remote${NORMAL}"
	else
	    echo "none"
	    N_local=0
	fi
	TAB=${TAB%$fTAB}
    else
	echo "not found"
    fi
    iHEAD="${iHEAD}~"
done

# compare local commit to remote commit
hash_remote=$(git log ${branch_pull} | grep -B4 "${subj_remote}" | head -n 1 | awk '{print $2}')
echo -n "${TAB}corresponding remote commit hash: "
echo $hash_remote
TAB+=${fTAB:='   '}
echo -n "${TAB}common commit has... "
if [ $hash_local == $hash_remote ]; then
    echo "the same hash"
    echo -n "${TAB}merge base: "
    git merge-base ${branch_local} ${branch_pull}
    hash_merge=$(git merge-base ${branch_local} ${branch_pull})
    echo -n "${TAB}common hash is... "
    if [ $hash_local == $hash_merge ]; then
	echo "the same as merge base"
    else
	echo "not the same as merge base"
    fi
else
    echo "a different hash (diverged)"
fi
#TAB=${TAB%$fTAB}

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
    echo -e "${TAB}${yellow}remote branch is $N_remote commits ahead of local${NORMAL}"
else
    echo "none"
    N_remote=0
fi

git_ver=$(git --version | awk '{print $3}')
git_ver_maj=$(echo $git_ver | awk -F. '{print $1}')
git_ver_min=$(echo $git_ver | awk -F. '{print $2}')
git_ver_pat=$(echo $git_ver | awk -F. '{print $3}')

# stash local changes
if [ -z "$(git diff)" ]; then
    echo "no differences to stash"
    b_stash=false
else
    git status
    echo "stashing differences..."

    if [ $git_ver_maj -lt 2 ]; then
	# old command
	git stash
    else
	# modern command
	git stash -u
    fi
    b_stash=true
fi

git checkout -b ${branch_local}.temp
git checkout ${branch_local}

# initiate HEAD
echo "resetting HEAD to $hash_remote..."
git reset --hard $hash_remote | sed "s/^/${TAB}/"

# pull remote commits
echo "${TAB}remote branch is $N_remote commits ahead of remote"
if [ $N_remote -gt 0 ];then
    echo "${TAB}pulling remote changes..."
    git pull
else
    echo "${TAB}no need to pull"
fi
cbar "done pulling"

# push local commits
echo "${TAB}local branch is $N_local commits ahead of remote"
if [ $N_local -gt 0 ];then
    echo "cherry-picking local changes..."
    if [ $N_local -gt 1 ];then
	if [ $git_ver_maj -lt 2 ]; then
	# old command
	    echo "${TAB}cherry picking multiple individual commits..."
	    git rev-list ${hash_start}^..${hash_end} | sed "s/^/${TAB}/"
	    echo -n "${TAB}in case of automatic cherry-pick failure, remember to push"
	    if $b_stash; then
		echo "and apply stash"
	    else
		echo
	    fi
	    git rev-list --reverse ${hash_start}^..${hash_end} | xargs -r -n1 git cherry-pick
	else
	# modern command
	    #git rev-list --reverse ${hash_start}^..$hash_end . | git cherry-pick --stdin
	    #git cherry-pick ${hash_start}^..$hash_end
	    git checkout ${branch_local}.temp
	    git rebase ${branch_local}
	    git checkout ${branch_local}
	    git merge ${branch_local}.temp
	    git branch -d ${branch_local}.temp
	fi
    else
	echo "single commit to cherry-pick"
	git cherry-pick ${hash_start}
    fi
    echo "pushing local changes..."
    git push --all
else
    echo "no need to cherry-pick"
fi
cbar "done pushing"

# get back to where you were....
N_stash=$(git stash list | wc -l)
if [ $N_stash -gt 0 ]; then
    echo "there are $N_stash entries in stash"
    if $b_stash; then
	echo "${TAB}applying stash..."
	git stash pop
	echo -n "stash made... "
	if [ -z "$(git diff)" ]; then
	    echo "no changes"
	else
	    echo "changes!"
	    git reset HEAD
	fi
    else
	echo "${TAB}... but none are from this operation"
    fi
else
    echo "no stash entries"
fi
cbar "done un-stashing"
echo "you're done!"
