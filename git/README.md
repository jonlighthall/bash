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
Use `git log origin/master | grep -B4 "$(git log --format=%B -n 1)"`
to get the has of the commit on the remote, use the command
`git log origin/master | grep -B4 "$(git log --format=%B -n 1)" | head -n 1 | awk '{print $2}'`
Reset the local branch to the most recent common commit message on the remote
`git reset $(git log origin/master | grep -B4 "$(git log --format=%B -n 1)" | head -n 1 | awk '{print $2}')`
That should be it.
Your local branch should have updated history.qy
