# used to fix bad file extensions for OneDrive
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
	
	for bad in bat bin cmd exe out osx gz
	do
	    echo "replacing \".$bad\" with \"${sep}${bad}\"..."
	    for fname in $(find $1 -name "*.${bad}"); do
		mv -nv "$fname" "`echo $fname | sed "s/\.$bad/$sep$bad/"`";
	    done
	done
    else
	echo "$1 is not found"
	exit 1
    fi
fi
