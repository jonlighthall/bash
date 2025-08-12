# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e "$fpretty" ]; then
    source "$fpretty"
fi

# print source name at start
if ! (return 0 2>/dev/null); then
    set -eE
    trap 'echo -e "${BAD}ERROR${RESET}: exiting ${BASH_SOURCE##*/}..."' ERR
fi
print_source

# WARNING: This script rewrites Git history permanently
echo -e "${YELLOW}WARNING: This script will permanently rewrite Git history!${RESET}"
echo -e "${YELLOW}This action is irreversible and will change all commit hashes.${RESET}"
echo -e "${YELLOW}Make sure you have a backup of your repository.${RESET}"
echo
read -p "Do you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 0
fi

# Verify we're in a Git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo -e "${BAD}ERROR: Not in a Git repository${RESET}"
    exit 1
fi

# Verify git filter-repo is available
if ! command -v git-filter-repo >/dev/null 2>&1; then
    echo -e "${BAD}ERROR: git-filter-repo is not installed${RESET}"
    echo "Install with: pip install git-filter-repo"
    exit 1
fi

# parse remote
if [ -z "$(git branch -vv | grep \* | grep "\[")" ]; then
    echo "no remote tracking branch set for current branch"
else
    branch_tracking=$(git branch -vv | grep \* | sed 's/^.*\[//;s/\(]\|:\).*$//')
    echo -e "remote tracking branch is ${BLUE}${branch_tracking}${RESET}"
    name_remote="${branch_tracking%%/*}"
    echo "remote is name ${name_remote}"
    url_remote=$(git remote -v | grep "${name_remote}" | awk '{print $2}' | sort -u)
    echo "remote url is ${url_remote}"
    # parse branches
    branch_remote="${branch_tracking#*/}"
    echo "remote branch is ${branch_remote}"
fi
branch_local=$(git branch | grep \* | sed 's/^\* //')
echo -e " local branch is ${GREEN}${branch_local}${RESET}"

branch_list=$(git branch -va | sed 's/^*/ /' | awk '{print $1}' | sed 's|remotes/.*/||' | sort -u | sed '/HEAD/d')
echo "list of branches: "
echo "${branch_list}" | sed 's/^/   /'

export FILTER_BRANCH_SQUELCH_WARNING=1
if [ -f ./.git-rewrite ]; then
    rm -rdv ./.git-rewrite
fi

git filter-repo $@ --partial --commit-callback "${BASH_SOURCE%/*}/filter.py"

dtab
print_done
