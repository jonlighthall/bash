for fname in *.out; do
    mv "$fname" "`echo $fname | sed "s/.out/_out"`";
done
