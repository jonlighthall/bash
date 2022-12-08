# used to un-fix bad file extensions for OneDrive
# JCL Nov 2021

# define replacement seperator
sep=_._

if [ $# -eq 0 ]
then
    echo "Please provide a target directory"
    exit 1
else
    if [[ -d $1 ]]; then
	echo "found $1"
	
	for bad in bat bin cmd csh exe gz prf out osx
	do
	    echo "replacing \"${sep}${bad}\" with \".$bad\"..."
	    for fname in $(find $1 -name "*$sep$bad"); do
		mv -vn "$fname" "`echo $fname | sed "s/$sep$bad/.$bad/"`";
	    done
	done
    else
	echo "$1 is not found"
	exit 1
    fi
fi
