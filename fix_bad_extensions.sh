sep=_._
for bad in out
do
    for fname in *.$bad; do
	mv -nv "$fname" "`echo $fname | sed "s/.$bad/$sep$bad/"`";
    done
done
