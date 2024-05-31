# remove duplicate images

dname=diff.jpg

for fname in *-JCL-*; do
    echo $fname

    if [ -e "$fname" ]; then
        echo "file found"
    else
        echo "no files found"
        echo "exiting..."
        exit 1
    fi

    fname2=${fname/-JCL-Spectre-i7-Vega/}
    echo $fname2

    if [ -e "$fname2" ]; then

    compare -compose src "${fname}" "${fname2}" ${dname}

    convert ${dname} -scale 1x1! -format "%[fx:u]\n" info:

    if [ $(convert ${dname} -scale 1x1! -format "%[fx:u]\n" info:) -eq 1 ]; then        
        echo "delte"
        rm -v "${fname}" ${dname}
    else
        echo "keep"
    fi

    else
        echo "not found"
    fi
    
done
