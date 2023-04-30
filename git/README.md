## git filter-
The `filter-reo` scripts are preferred, but the `filter-branch` scripts are included for use on systems that do not have `filter-repo` installed.
### Settings
Before running, check the individual scripts and confirm that the author emails are correct.
The scripts can take inputs such as `--force` or `--prune-empty`
### Execution
Fist, make sure your local repository is up to date
```
git fetch origin
git status
git pull origin master
git diff origin/master
```
Then rewrite history and push the changes
```
bash ~/utils/bash/git/filter-repo-author.sh
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
Use `git log origin/master | grep -B4 "$(git log --format=%B -n 1)"`
to get the has of the commit on the remote, use the command
`git log origin/master | grep -B4 "$(git log --format=%B -n 1)" | head -n 1 | awk '{print $2}'`

If the most recent local commit does not match a remote commit, identify the most recent common commit with the following commands.
`git log origin/master | grep -B4 "commit message"`
or
`git log origin/master | grep -B4 "$(git log HEAD~ --format=%B -n 1)"`

Note the commit hashes of the local commits that are not on the remote

Reset the local branch to the most recent common commit message on the remote
`git reset $(git log origin/master | grep -B4 "$(git log --format=%B -n 1)" | head -n 1 | awk '{print $2}')`

If necessary, merge, fast-forward, or cherry-pick the outstanding commits from the local repository
Similaryly, pull the remainign commits from the remote.

That should be it.
Your local branch should have updated history.qy
