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

for branch in $branch_list
do
    git checkout $branch
    git fetch ${name_remote} ${branch}
    git log ${name_remote}/${branch} --pretty=format:"%aN %aE" | sort | uniq -c | sort -n
    git diff ${branch} ${name_remote}/${branch}

    N=$(git log ${name_remote}/${branch} --pretty=format:"%aN %aE" | sort -u | wc -l)
    if [ $N -gt 1 ]; then
	echo "more than one author"

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
    '
	git push -f ${name_remote} ${branch}
    else
	echo "only one author!"
	git log --pretty=format:"%aN %aE" | sort | uniq -c | sort -n
	M=$(git log --pretty=format:"%aN %aE" | sort -u | wc -l)
	if [ $M -gt 1 ]; then
	    echo "more than one author"
	    force_pull
	else
	    echo "only one author!"
	fi

	if [ N==1 ] && [ M==1 ] && [ -z "$(git diff ${branch} ${name_remote}/${branch})" ]; then
	    git reset ${name_remote}/${branch}
	else
	    echo "unsafe to reset"
	fi
    fi
done
git checkout ${branch_local}