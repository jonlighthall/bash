# remove duplicate images

dname=diff.jpg

list=( "-DTWUSC001" "-LPWUD110" "-JCL-Spectre-i7-Vega" )
for suff in ${list[@]}; do
    for fname in *${suff}*; do
        echo $fname

        if [ -e "$fname" ]; then
            echo "file found"
        else
            echo "no files found"
            echo "exiting..."
            exit 1
        fi

        fname2=${fname//"${suff}"/}
        echo -n "   original file ${fname2}... "

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
done
