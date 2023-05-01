#/bin/bash
unset hash_local
hash_local=$(git log | grep -B4 "$(git log origin/master --format=%s -n 1)" | head -n 1 | awk '{print $2}')
if [ ! -z ${hash_local} ]; then
    echo $hash_local
    git rev-list $hash_local..HEAD
    unset hash_start
    hash_start=$(git rev-list $hash_local..HEAD | tail -n 1)
    unset hash_end
    hash_end=$(git rev-list $hash_local..HEAD | head -n 1)
fi
unset hash_remote
hash_remote=$(git log origin/master | grep -B4 "$(git log $hash_local --format=%s -n 1)" | head -n 1 | awk '{print $2}')
git stash
if [ ! -z ${hash_start} ]; then
    git reset --hard $hash_remote
    git cherry-pick ${hash_start}^..$hash_end
else
    git reset $hash_remote
fi
git pull
