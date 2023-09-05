DUMMY=dummy
fname=parent.sh
if [ -f $fname ]; then
    echo -e "\nexecute ${fname} in subshell:"
    ./$fname
    echo -e "\nsource ${fname} in same shell:"
    . $fname
    echo -e "\n${SHELL} ${fname}:"
    $SHELL $fname
fi
