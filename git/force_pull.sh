#/bin/bash
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
echo "pulling from ${name_remote}/${name_branch}"
subj_remote=$(git log ${name_remote}/${name_branch} --format=%s -n 1)
echo "remote commit subject: $subj_remote"
unset hash_local
hash_local=$(git log | grep -B4 "$subj_remote" | head -n 1 | awk '{print $2}')

echo -n "corresponding local commit hash: "
if [ ! -z ${hash_local} ]; then
    echo "$hash_local"
    echo "trailing local commits: "
    unset hash_start
    hash_start=$(git rev-list $hash_local..HEAD | tail -n 1)
    if [ ! -z ${hash_start} ]; then
	git rev-list $hash_local..HEAD
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
exit
unset hash_remote
hash_remote=$(git log ${name_remote}/${name_branch} | grep -B4 "$(git log $hash_local --format=%s -n 1)" | head -n 1 | awk '{print $2}')
git stash
if [ ! -z ${hash_start} ]; then
    git reset --hard $hash_remote
    git cherry-pick ${hash_start}^..$hash_end
else
    git reset $hash_remote
fi
git pull
