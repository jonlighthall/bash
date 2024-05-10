
dname=diff.jpg

for fname in *-JCL-*; do
    echo $fname
    fname2=${fname/-JCL-Spectre-i7-Vega/}
    echo $fname2

    compare -compose src ${fname} ${fname2} ${dname}

    convert ${dname} -scale 1x1! -format "%[fx:u]\n" info:

    if [ $(convert ${dname} -scale 1x1! -format "%[fx:u]\n" info:) -eq 1 ]; then        
        echo "delte"
        rm -v ${fname} ${dname}
    else
        echo "keep"
    fi
    
done
