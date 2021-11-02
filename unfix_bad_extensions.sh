# used to un-fix bad file extensions for OneDrive
# JCL Nov 2021

# define replacement seperator
sep=_._

for bad in out exe bat
do
    echo "replacing \"${sep}${bad}\" with \".$bad\"..."
    for fname in $(find $PWD -name "*$sep$bad"); do
	mv -nv "$fname" "`echo $fname | sed "s/$sep$bad/.$bad/"`";
    done
done
