#/bin/bash

# git/force_pull.sh - the remote name and branch can be optionally specified by the first and
# second arguments, respectively. The default remote tracking branch is origin/master.

# JCL Apr 2023

TAB="   "
set -e

# parse arguments
if [ $# -lt 1 ]; then
    name_remote=origin
else
    name_remote=$1
fi
if [ $# -lt 2 ]; then
    name_branch=master
else
    name_branch=$2
fi

# determine latest common local commit, based on commit message
tracking=${name_remote}/${name_branch}
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
	    N=$(git rev-list $hash_local..HEAD | wc -l)
	    if [ $N -gt 1 ]; then
		echo -n "or ${hash_start}^.."
		hash_end=$(git rev-list $hash_local..HEAD | head -n 1)
		echo ${hash_end}
	    else
		hash_end=$hash_start
	    fi
	    echo "${TAB}local branch is $N commits ahead of remote"
	else
	    echo "none"
	fi
    else
	echo "not found"
    fi
    tracking="${tracking}~"
done

# determine local commits not found on remote
hash_remote=$(git log ${name_remote}/${name_branch} | grep -B4 "${subj_remote}" | head -n 1 | awk '{print $2}')
echo -n "${TAB}corresponding remote commit hash: "
echo $hash_remote
echo -n "common commit has... "
if [ $hash_local == $hash_remote ]; then
    echo "the same hash"
    git merge-base ${name_branch} ${name_remote}/${name_branch}
    hash_merge=$(git merge-base ${name_branch} ${name_remote}/${name_branch})
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
hash_start_remote=$(git rev-list $hash_remote..${name_remote}/${name_branch} | tail -n 1)
if [ ! -z ${hash_start_remote} ]; then
    echo
    git rev-list $hash_remote..${name_remote}/${name_branch} | sed "s/^/${TAB}/"
    N_remote=$(git rev-list $hash_remote..${name_remote}/${name_branch} | wc -l)
    if [ $N_remote -gt 1 ]; then
	echo -n "or ${hash_start_remote}^.."
	hash_end_remote=$(git rev-list $hash_remote..${name_remote}/${name_branch} | head -n 1)
	echo ${hash_end_remote}
    else
	hash_end_remote=$hash_start_remote
    fi
    echo "${TAB}remote branch is $N_remote commits ahead of remote"
else
    echo "none"
fi

exit
# stash local changes
echo "stashing changes..."
git stash -u

# intiate pull
echo "resetting HEAD to $hash_remote..."
if [ ! -z ${hash_start} ]; then
    git reset --hard $hash_remote
    echo "cherry-picking local changes..."
    if [ ${hash_start} == ${hash_end} ]; then
	echo "single commit to cherry-pick"
	git cherry-pick ${hash_start}
    else
	git cherry-pick ${hash_start}^..$hash_end
    fi
else
    git reset $hash_remote
fi
exit
echo "applying stash..."
git stash apply
echo -n "stash made... "
if [ -z $(git diff) ]; then
    echo "no changes"
    echo "pulling remote changes..."
    git pull
else
    echo "changes!"
fi
