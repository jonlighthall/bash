# used to un-fix bad file extensions for OneDrive
sep=_._
for bad in out exe bat
do
    for fname in *$sep$bad; do
	mv -nv "$fname" "`echo $fname | sed "s/$sep$bad/.$bad/"`";
    done
done
