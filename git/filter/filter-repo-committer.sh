# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
    source $fpretty
fi

# print source name at start
if ! (return 0 2>/dev/null); then
    set -eE
    trap 'echo -e "${BAD}ERROR${RESET}: exiting ${BASH_SOURCE##*/}..."' ERR
fi
print_source

# parse remote
if [ -z "$(git branch -vv | grep \* | grep "\[")" ]; then
    echo "no remote tracking branch set for current branch"
else
    branch_tracking=$(git branch -vv | grep \* | sed 's/^.*\[//;s/\(]\|:\).*$//')
    echo -e "remote tracking branch is ${BLUE}${branch_tracking}${RESET}"
    name_remote=${branch_tracking%%/*}
    echo "remote is name $name_remote"
    url_remote=$(git remote -v | grep ${name_remote} | awk '{print $2}' | sort -u)
    echo "remote url is ${url_remote}"
    # parse branches
    branch_remote=${branch_tracking#*/}
    echo "remote branch is $branch_remote"
fi
branch_local=$(git branch | grep \* | sed 's/^\* //')
echo -e " local branch is ${GREEN}${branch_local}${RESET}"

branch_list=$(git branch -va | sed 's/^*/ /' | awk '{print $1}' | sed 's|remotes/.*/||' | sort -u | sed '/HEAD/d')
echo "list of branches: "
echo "${branch_list}" | sed 's/^/   /'

export FILTER_BRANCH_SQUELCH_WARNING=1
if [ -f ./.git-rewirte ]; then
    rm -rdv ./.git-rewrite
fi

git filter-repo $@ --partial --commit-callback '
# define correct name
CORRECT_NAME = b"Jon Lighthall"

# define correct email
CORRECT_EMAIL = b"jon.lighthall@gmail.com"

# list emails to replace
auth_list = [b"jonlighthall@users.noreply.github.com"]
# define list file
file_name = os.path.expanduser("~/utils/bash/git/filter/author_list.txt")
# check if file exists
if os.path.isfile(file_name):
    # File exists
    with open(file_name, "r", encoding="us-ascii") as file:
        for line in file:
            auth_list.append(line.strip().encode())
else:
    # File not found, print error message
    print("Error: File not found")

# conditionally replace emails and names
if commit.committer_email in auth_list:
    if commit.committer_email != CORRECT_EMAIL:
        commit.committer_email = CORRECT_EMAIL
    if commit.committer_name != CORRECT_NAME:
        commit.committer_name = CORRECT_NAME
'

dtab
print_done
