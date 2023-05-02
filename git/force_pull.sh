#/bin/bash
# git/force_pull.sh - the remote name and branch can be optionally specified by the first and
# second arguments, respectively. The default remote tracking branch is origin/master.

# JCL Apr 2023

TAB="   "
set -e

# parse arguments
branch_tracking=$(git branch -vv | grep \* | sed 's/^.*\[//;s/].*$//')
echo "remote tracking branch is $branch_tracking"
branch_local=$(git branch | grep \* | sed 's/^\* //')
echo "local branch is $branch_local"
if [ $# -lt 1 ]; then
    name_remote=${branch_tracking%%/*}
else
    name_remote=$1
fi
if [ $# -lt 2 ]; then
    branch_remote=${branch_tracking#*/}
else
    branch_remote=$2
fi
branch_pull=${name_remote}/${branch_remote}
echo "pulling from remote branch $branch_pull"

# determine latest common local commit, based on commit message
tracking=${branch_pull}
while [ -z ${hash_local} ]; do
    echo "pulling from ${tracking}"
    subj_remote=$(git log ${tracking} --format=%s -n 1)
    echo "${TAB}remote commit subject: $subj_remote"
    hash_local=$(git log | grep -B4 "$subj_remote" | head -n 1 | awk '{print $2}')
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

# stash local changes
echo "stashing changes..."
git stash -u

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

# push local commits
echo "${TAB}local branch is $N_local commits ahead of remote"
if [ $N_local -gt 0 ];then
    echo "cherry-picking local changes..."
    if [ $N_local -gt 1 ];then
	git cherry-pick ${hash_start}^..$hash_end
    else
	echo "single commit to cherry-pick"
	git cherry-pick ${hash_start}
    fi
    git push --all
else
    echo "no need to cherry-pick"
fi

# get back to where you were....
N_stash=$(git stash list | wc -l)
if [ $N_stash -gt 0 ]; then
    echo "there are $N_stash entries in stash"
    echo "applying stash..."
    git stash pop
    echo -n "stash made... "
    if [ -z $(git diff) ]; then
	echo "no changes"
    else
	echo "changes!"
	git reset HEAD
	echo "do something!"
    fi
fi
echo "you're done!"
