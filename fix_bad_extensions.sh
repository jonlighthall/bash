# used to un-fix bad file extensions for OneDrive
sep=_._
for bad in out exe bat
do
    for fname in *.$bad; do
	mv -nv "$fname" "`echo $fname | sed "s/.$bad/$sep$bad/"`";
    done
done
