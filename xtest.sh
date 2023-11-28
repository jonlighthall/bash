#!/bin/bash -u
echo "${0##*/}"

# test X11
export LC_ALL=C
list_test="xeyes xclock xcalc xman xlogo xterm"
list_found=''

for prog in $list_test; do
    echo -e "opening $prog... \c"
    $prog 2>/dev/null &
    if ! command -v $prog &>/dev/null; then
        echo "not found"
    else
        echo "OK"
        list_found="$list_found $prog"
    fi
done

if [ -z "${list_found}" ]; then
    echo "FAIL: no X-programs found!"
    exit
fi

# close windows
read -n 1 -s -r -p "Press any key to continue"
echo
for prog in $list_found; do
    echo "closing $prog..."
    pkill $prog 2>/dev/null &
done
