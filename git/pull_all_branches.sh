# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# print source name at start
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
    set -eE
    trap 'echo -e "${BAD}ERROR${RESET}: exiting ${BASH_SOURCE##*/}..."' ERR
fi
print_source

# parse remote
bar 56 "remote"
if [ -z "$(git branch -vv | grep \* | grep "\[")" ]; then
    echo "no remote tracking branch set for current branch"
else
    remote_tracking_branch=$(git branch -vv | grep \* | sed 's/^.*\[//;s/\(]\|:\).*$//')
    echo -e "remote tracking branch is ${BLUE}${remote_tracking_branch}${RESET}"
    remote_name=${remote_tracking_branch%%/*}
    echo "remote is name $remote_name"
    remote_url=$(git remote -v | grep ${remote_name} | awk '{print $2}' | sort -u)
    echo "remote url is ${remote_url}"
    branch_remote=${remote_tracking_branch#*/}
    echo "remote branch is $branch_remote"
fi

bar 56 "branch"
# parse branches
branch_local=$(git branch | grep \* | sed 's/^\* //')
echo -e " local branch is ${GREEN}${branch_local}${RESET}"
branch_list=$(git branch -va | sed 's/^*/ /' | awk '{print $1}' | sed 's|remotes/.*/||' | sort -u | sed '/HEAD/d')
echo "list of all branches: "
echo "${branch_list}" | sed "s/^/${fTAB}/"

branch_list_remote=$(git branch -va | sed '/remote/!d' | awk '{print $1}' | sed 's|remotes/.*/||' | sort -u | sed '/HEAD/d')
echo "list of remote branches: "
echo "${branch_list_remote}" | sed "s/^/${fTAB}/"

branch_list_track=$(git branch -vva | grep "\[" | sed 's/^*/ /' | awk '{print $1}')
echo "list of local branches with remote tracking: "
echo "${branch_list_track}" | sed "s/^/${fTAB}/"

branch_list_no_track=$(git branch -vva | sed '/remote/d' | sed '/\[/d' | awk '{print $1}')
echo "list of local branches with no remote tracking: "
echo "${branch_list_no_track}" | sed "s/^/${fTAB}/"

branch_list_pull=$(echo $branch_list_remote $branch_list_track | sed 's/ /\n/g' | sort -u)
echo "list of branches to loop through: "
echo "${branch_list_pull}" | sed "s/^/${fTAB}/"

# stash local changes
echo -n "stashing differences on branch ${branch_local}... "
if [ -z "$(git diff)" ]; then
    echo "no differences to stash"
    b_stash=false
else
    git status
    #git stash
    echo "done"
    b_stash=true
fi

echo "start looping through branches..."
for branch in $branch_list_pull; do
    bar 56 "$(git checkout $branch 2>&1)"
    remote_tracking_branch=$(git branch -vv | grep \* | sed 's/^.*\[//;s/\(]\|:\).*$//')
    echo -e "remote tracking branch is ${BLUE}${remote_tracking_branch}${RESET}"
    remote_name=${remote_tracking_branch%%/*}

    git fetch ${remote_name} ${branch}
    list_fmod=$(git --no-pager diff --name-only ${branch} ${remote_tracking_branch})
    if [ ${#list_fmod} -gt 0 ]; then
        echo "list of modified files:"
        echo ${list_fmod} | sed "s/ /\n/g" | sed "s/^/${fTAB}/g"
    fi
    list_comm_loc=$(git rev-list ${branch}..${remote_tracking_branch})
    if [ ${#list_comm_loc} -gt 0 ]; then
        echo "list of trailing commits:"
        echo ${list_comm_loc} | sed "s/ /\n/g" | sed "s/^/${fTAB}/g"
    fi
    list_comm_rem=$(git rev-list ${remote_tracking_branch}..${branch})
    if [ ${#list_comm_rem} -gt 0 ]; then
        echo "list of leading commits:"
        echo ${list_comm_rem} | sed "s/ /\n/g" | sed "s/^/${fTAB}/g"
    fi

done
exit

# determine latest common local commit, based on commit message
tracking==${remote_name}/${branch_remote}
while [ -z ${hash_local} ]; do
    echo "pulling from ${tracking}"
    subj_remote=$(git log ${tracking} --format=%s -n 1)
    time_remote=$(git log ${tracking} --format=%at -n 1)
    echo "${TAB}remote commit subject: $subj_remote"

    hash_local=$(git log | grep -B4 "$subj_remote" | head -n 1 | awk '{print $2}')

    hash_local_t=$(git log --format="%at %H " | grep "$time_remote" | awk '{print $2}')

    echo "subject and time hashes..."
    if [ "$hash_local" == "$hash_local_t" ]; then
        echo "match"
    else
        echo "do not match"
        echo $hash_local
        echo $hash_local_t
        exit 1
    fi
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

# dummy loop to match formatting
for i in 1; do
    # determine number of authors on remote branch
    echo "remote:"
    git log ${remote_name}/${branch} --pretty=format:"%aN %aE" | sort | uniq -c | sort -n
    N=$(git log ${remote_name}/${branch} --pretty=format:"%aN %aE" | sort -u | wc -l)
    if [ $N -gt 1 ]; then
        echo "${TAB}${GRH}more than one author on remote branch ${remote_name}/${branch} (N=$N)${RESET}"
        echo "${TAB}filtering repo..."
        ${HOME}/utils/bash/git/filter-repo-author.sh $@
        echo "${TAB}done filtering repo"
        echo "${TAB}force pushing rewrite..."
        git push -f ${remote_name} ${branch}
    else
        echo "${TAB}only one author on remote branch ${remote_name}/${branch}!"
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
                git branch --set-upstream-to=${remote_name}/${branch} ${branch}
            fi

            ver=$(git --version | awk '{print $3}')
            ver_maj=$(echo $ver | awk -F. '{print $1}')
            ver_min=$(echo $ver | awk -F. '{print $2}')
            ver_pat=$(echo $ver | awk -F. '{print $3}')

            # determine number commits local branch is behind remote
            if [ $ver_maj -lt 2 ]; then
                echo "pulling commits"
                git pull ${remote_name} ${branch}
            else
                if [ -z $(git rev-list --left-only ${remote_name}/${branch}...${branch}) ]; then
                    echo "no commits to pull"
                else
                    echo "pulling commits"
                    git pull ${remote_name} ${branch}
                fi
            fi

            # determine number commits local branch is ahead of remote
            if [ $ver_maj -lt 2 ]; then
                echo "pushing commits"
                git push ${remote_name}
                if [ -z $(git rev-list --right-only ${remote_name}/${branch}...${branch}) ]; then
                    echo "no commits to push"
                else
                    echo "pushing commits"
                    git push ${remote_name}
                fi
            fi

            # determine difference between local and remote
            if [ -z "$(git diff ${branch} ${remote_name}/${branch})" ]; then
                echo "no differences between local and remote"

                hash_remote=$(git rev-parse ${remote_name}/${branch})
                hash_local=$(git rev-parse HEAD)
                echo -n "${TAB}local and remote hashes..."
                if [[ "$hash_remote" == "$hash_local" ]]; then
                    echo -e "${GOOD}match${RESET}"
                else
                    echo -e "${BAD}no not match${RESET}"
                    echo $hash_local
                    echo $hash_remote

                    echo "reseting HEAD to ${remote_name}/${branch}..."
                    git reset ${remote_name}/${branch}
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
