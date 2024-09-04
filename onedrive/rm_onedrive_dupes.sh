# remove duplicate images

# define name for temporary image difference file
dname=diff.jpg

# define OneDrive duplice suffixes
list=( "-DTWUSC001" "-LPWUD110" "-JCL-Spectre-i7-Vega" )
# loop over suffixes
for suff in ${list[@]}; do
    # loop over matching file names
    for fname in *${suff}*; do
        echo $fname

        if [ -e "$fname" ]; then
            echo "   duplicate file found"
        else
            echo "   no files found"
            echo "   exiting..."
            exit 1
        fi

        # strip suffix
        fname2=${fname//"${suff}"/}
        echo -n "   original file ${fname2}... "

        # look for original file name
        if [ -e "$fname2" ]; then
            echo "found"

            # get file type
            type="$(file ${fname})"
            echo "   $type"

            # use diff for text files
            if [[ "${type}" == *"ASCII"* ]]; then
                echo    "   text"

                # diff files
                diff -EZbwB "${fname}" "${fname2}" &>/dev/null

                RETVAL=$?
                if [ $RETVAL = 0 ]; then
                    echo "   delete"
                    echo -n "   "
                    rm -v "${fname}"
                else
                    echo "   keep"
                fi
            fi

            # use ImageMagick for images
            if [[ "${type}" == *"image"* ]]; then
                echo "   image"
                # save image differences to temporary file
                compare -compose src "${fname}" "${fname2}" ${dname}
                # compress differences down to one pixel
                echo -n "   diff pixel average: "
                convert ${dname} -scale 1x1! -format "%[fx:u]\n" info:

                # if the pixel value is 1, the diff image is all black and there
                # are no diffrences
                if [ $(convert ${dname} -scale 1x1! -format "%[fx:u]\n" info:) -eq 1 ]; then
                    echo "   delete"
                    rm -v "${fname}"
                else
                    echo "   keep"
                fi
                rm -v "${dname}"
            fi
        else
            echo "not found"
            mv -v "${fname}" "${fname2}"
        fi
    done
done
