# git

Git bash scripts.

## general

| script               | description                           |
| -------------------- | ------------------------------------  |
| [`apply_hashes`](apply_hashes.sh) | |
| [`force_pull`](force_pull.sh) | |
| [`gita`](gita.sh) | |
| [`gitac`](gitac.sh) | |
| [`gitact`](gitact.sh) | |
| [`pull_all_branches`](pull_all_branches.sh) | |
| [`set_config`](set_config.sh) | |
| [`sort_hash`](sort_hash.sh) | |
| [`undel_repo`](undel_repo.sh) | |
| [`update_repos`](update_repos.sh) | |

## git filter-

The `filter-repo` scripts are preferred, but the `filter-branch` scripts are included for use on systems that do not or cannot have `filter-repo` installed.

### `filter-branch`

Author names can be rewritten with the following code

from <https://help.github.com/articles/changing-author-info/>

````bash
./change.sh
git push --force --tags origin 'refs/heads/*'
````

| script               | description                           |
| -------------------- | ------------------------------------  |
| [`filter-branch-author`](filter-branch-author.sh) | |
| [`filter-branch-committer`](filter-branch-committer.sh) | |
| [`filter-branch-email`](filter-branch-email.sh) | |
| [`filter-branch-hello`](filter-branch-hello.sh) | |

### `filter-repo`

| script               | description                           |
| -------------------- | ------------------------------------  |
| [`filter-repo-author`](filter-repo-author.sh) | |
| [`filter-repo-author-loop`](filter-repo-author-loop.sh) | |
| [`filter-repo-committer`](filter-repo-committer.sh) | |
| [`filter-repo-email`](filter-repo-email.sh) | |
| [`unfilter-repo-author`](unfilter-repo-author.sh) | |

### Settings

Before running, check the individual scripts and confirm that the author emails are correct.
Unlisted urls maybe saved in the file [`url.txt`](url.txt).
To keep changes to `url.txt` unreported (and ignore upstream changes), the following command may be used

```bash
git update-index --skip-worktree url.txt
```

to undo this action, use the following command

```bash
git update-index --no-skip-worktree url.txt
```

The scripts can take inputs such as `--force` or `--prune-empty`

### Execution

Fist, make sure your local repository is up to date

```bash
git fetch origin
git status
git pull origin master
git diff origin/master
```

Then rewrite history and push the changes

```bash
bash ${HOME}/utils/bash/git/filter-repo-author.sh
git fetch
git push --force-with-lease
```

### Aftermath

If the filter scripts are utilized, it will case diverging commits with the remote repository.
To address this, the following steps must be taken.
Locate the local repository that has not been updated.
Use `git fetch origin` to get an updated list of remote commits.
Use `git log -n 1` to view the most recent commit on the local repository.
Note the commit message or use the command `git log -n 1 --format=%H`

Look for the corresponding commit on the  remote.
This will work even if the remote has commits that the local remote is missing.
Use `git log origin/master | grep -B4 "$(git log --format=%s -n 1)"`
to get the has of the commit on the remote, use the command
`git log origin/master | grep -B4 "$(git log --format=%s -n 1)" | head -n 1 | awk '{print $2}'`

If the most recent local commit does not match a remote commit, identify the most recent common commit with the following commands.
`git log origin/master | grep -B4 "commit message"`
or
`git log origin/master | grep -B4 "$(git log HEAD~ --format=%s -n 1)"`

get the most recent common local commit with the following command
`git log | grep -B4 "$(git log origin/master --format=%s -n 1)" | head -n 1 | awk '{print $2}'`
or

```bash
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
```

Note the commit hashes of the local commits that are not on the remote
git rev-list $(git log | grep -B4 "$(git log origin/master --format=%s -n 1)" | head -n 1 | awk '{print $2}')..HEAD

Reset the local branch to the most recent common commit message on the remote
`git reset $(git log origin/master | grep -B4 "$(git log --format=%s -n 1)" | head -n 1 | awk '{print $2}')`

Nominally, the following commands should work

```bash
git fetch origin
git diff origin/master
git reset $(git log origin/master | grep -B4 "$(git log --format=%s -n 1)" | head -n 1 | awk '{print $2}')
```

If necessary, merge, fast-forward, or cherry-pick the outstanding commits from the local repository
Similarly, pull the remaining commits from the remote.

That should be it.
Your local branch should have updated history.
