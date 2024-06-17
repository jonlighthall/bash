# remove duplicate images

dname=diff.jpg

list=( "-DTWUSC001" "-LPWUD110" "-JCL-Spectre-i7-Vega" )
for suff in ${list[@]}; do
    for fname in *${suff}*; do
        echo $fname

        if [ -e "$fname" ]; then
            echo "   duplicate file found"
        else
            echo "   no files found"
            echo "   exiting..."
            exit 1
        fi

        fname2=${fname//"${suff}"/}
        echo -n "   original file ${fname2}... "

        if [ -e "$fname2" ]; then
            echo "found"
            type="$(file ${fname})"
            echo "   $type"

            if [[ "${type}" == *"ASCII"* ]]; then
                echo    "   text"

                # diff files
                diff "${fname}" "${fname2}" &>/dev/null

                RETVAL=$?
                if [ $RETVAL = 0 ]; then
                    echo "   delete"
                    echo -n "   "
                    rm -v "${fname}"
                else
                    echo "   keep"
                fi
            fi

            if [[ "${type}" == *"image"* ]]; then
                echo "   image"
                compare -compose src "${fname}" "${fname2}" ${dname}
                echo -n "   diff pixel average: "
                convert ${dname} -scale 1x1! -format "%[fx:u]\n" info:

                if [ $(convert ${dname} -scale 1x1! -format "%[fx:u]\n" info:) -eq 1 ]; then
                    echo "   delete"
                    rm -v "${fname}" "${dname}"
                else
                    echo "   keep"
                fi
            fi
        else
            echo "not found"
        fi
    done
done
