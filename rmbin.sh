# Used to delete binary files from directory. Tracked binary files
# found in a Git repository will be removed from the repository. The
# .git directory will not be searched. JCL Nov 2021

if [ $# -eq 0 ]
then
    echo "Please provide a target directory"
    exit 1
else
    if [[ -d $1 ]]; then
	echo "found $1"	

	cd $1
	echo $PWD

	if git rev-parse --git-dir > /dev/null 2>&1; then
	    # This is a valid git repository
	    echo "$1 is part of a Git repository"
	    GITDIR=$(git rev-parse --git-dir)
	    echo "the .git folder is $GITDIR"

	    # first, remove tracked files from the repository
	    echo "removing tracked binary files from the repository..."
	    find ./ -type f -not -path "*$GITDIR/*" | perl -lne 'print if -B' | xargs -r git rm --ignore-unmatch

	    # then, remove remaining binary files
	    echo "removing untracked binary files..."
	    find ./ -type f -not -path "*$GITDIR/*" | perl -lne 'print if -B' | xargs -r rm -v
	else
	    # this is not a git repository
	    echo "$1 is not part of a Git repsoity"
	    echo "removing binary files..."
	    find ./ -type f | perl -lne 'print if -B' | xargs -r rm -v
	fi
    else
	echo "$1 is not found"
	exit 1
    fi
fi
