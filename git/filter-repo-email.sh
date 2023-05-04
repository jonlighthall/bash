set -e
# parse remote
if [ -z "$(git branch -vv | grep \* | grep "\[")" ]; then
    echo "no remote tracking branch"
else
    branch_tracking=$(git branch -vv | grep \* | sed 's/^.*\[//;s/\(]\|:\).*$//')
    echo -e "remote tracking branch is \033[34m${branch_tracking}\033[m"
    name_remote=${branch_tracking%%/*}
    echo "remote is name $name_remote"
    url_remote=$(git remote -v | grep ${name_remote} |  awk '{print $2}' | sort -u)
    echo "remote url is ${url_remote}"
    # parse branches
    branch_remote=${branch_tracking#*/}
    echo "remote branch is $branch_remote"
fi
branch_local=$(git branch | grep \* | sed 's/^\* //')
echo -e " local branch is \033[32m${branch_local}\033[m"

branch_list=$(git branch -va | sed 's/^*/ /' |  awk '{print $1}' | sed 's|remotes/.*/||' | sort -u | sed '/HEAD/d')
echo "list of branches: "
echo "${branch_list}" | sed 's/^/   /'

git filter-repo $@ --partial --commit-callback '
    correct_name = b"Jon Lighthall"
    auth_list = [b"jlighthall@fsu.edu",b"lighthall@lsu.edu"]
    auth_list.append(b"jonlighthall@users.noreply.github.com")
    auth_list.append(b"jon.lighthall@ygmail.com")
    auth_list.append(b"jonathan.lighthall@")
    auth_list.append(b"jonathan.c.lighthall@")
    correct_email = b"jon.lighthall@gmail.com"
    if commit.author_email in auth_list:
        commit.author_email = correct_email
        if commit.author_name != correct_name:
            commit.author_name = correct_name
    if commit.committer_email in auth_list:
        commit.committer_email = correct_email
        if commit.committer_name != correct_name:
            commit.committer_name = correct_name
    if commit.tagger_email in auth_list:
        commit.tagger_email = correct_email
        if commit.tagger_name != correct_name:
            commit.tagger_name = correct_name
'
