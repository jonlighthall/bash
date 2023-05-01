#/bin/bash
TAB="   "
set -e
#set -x
unset hash_remote_head
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
tracking=${name_remote}/${name_branch}
unset hash_local
while [ -z ${hash_local} ]; do
    echo "pulling from ${tracking}"
    subj_remote=$(git log ${tracking} --format=%s -n 1)
    echo "${TAB}remote commit subject: $subj_remote"
    hash_local=$(git log | grep -B4 "$subj_remote" | head -n 1 | awk '{print $2}')
    echo -n "${TAB}corresponding local commit hash: "
    if [ ! -z ${hash_local} ]; then
	echo "$hash_local"
	echo -n "${TAB}trailing local commits: "
	unset hash_start
	hash_start=$(git rev-list $hash_local..HEAD | tail -n 1)
	if [ ! -z ${hash_start} ]; then
	    echo
	    git rev-list $hash_local..HEAD | sed "s/^/${TAB}/"
	    echo -n "or ${hash_start}^.."
	    unset hash_end
	    hash_end=$(git rev-list $hash_local..HEAD | head -n 1)
	    echo ${hash_end}
	else
	    echo "none"
	fi
    else
	echo "not found"
    fi
    tracking="${tracking}~"
done
unset hash_remote
hash_remote=$(git log ${name_remote}/${name_branch} | grep -B4 "${subj_remote}" | head -n 1 | awk '{print $2}')
echo -n "${TAB}corresponding remote commit hash: "
echo $hash_remote
echo "stashing changes..."
git stash --all
echo "resetting HEAD to $hash_remote..."
if [ ! -z ${hash_start} ]; then
    git reset --hard $hash_remote
    echo "cherry-picking local changes..."
    git cherry-pick ${hash_start}^..$hash_end
else
    git reset $hash_remote
fi
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
