fname=parent.sh
if [ -f $fname ]; then
    ./$fname
    . $fname
    $SHELL $fname
fi
