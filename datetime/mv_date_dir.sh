#!/bin/bash

# get canonical source name

echo "${BASH_SOURCE}"
echo "$(readlink -f "${BASH_SOURCE}")"
echo "$(dirname "$(readlink -f "${BASH_SOURCE}")")"

src_dir_phys="$(dirname "$(readlink -f "${BASH_SOURCE}")")"
echo "${src_dir_phys}"

. "${src_dir_phys}"/date_dir.sh

echo
# use  most common date
echo "most common:"
dir_out=${cdate}_${name_in}
if [[ "${dir_in}" == "${dir_out}" ]]; then
    echo "   no change"
else
    echo "   mv -nv ${dir_in} ${dir_out}"
fi

if [[ "${cdate}" == "${mdate}" ]]; then
    echo "same"
else

    # use newest date
    echo "newest:"
    dir_out=${mdate}_${name_in}
    if [[ "${dir_in}" == "${dir_out}" ]]; then
        echo "   no change"
    else
        echo "   mv -nv ${dir_in} ${dir_out}"
        #    mv -nv ${dir_in} ${mdate}_${name_in}
    fi
fi
