# used to un-fix bad file extensions for OneDrive
# JCL Nov 2021

# define replacement seperator
sep=_._

for bad in out exe bat
do
    echo "replacing \".$bad\" with \"${sep}${bad}\"..."
    for fname in $(find $PWD -name "*.${bad}"); do
	mv -nv "$fname" "`echo $fname | sed "s/.$bad/$sep$bad/"`";
    done
done
