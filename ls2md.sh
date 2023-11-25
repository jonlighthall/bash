#!/bin/bash -u
#
# ls2md.sh - convert directory contents to markdown links. Used for creating a table of contents
# for git readme files. Optional argument specifies the file extenstion. Default is '.sh'
#
# Jun 2023 JCL

if [ $# -eq 0 ]; then
    echo "No argument specified. Using default"
    arg=".sh"
else
    echo "Specified argument = $@"
    arg=$@
fi

fname=ls2md.md

for ext in $arg; do
    echo "filtering $arg"
    find -L ./ -not -path "*/.git*/*" -type f -name "*${ext}" | sed "s,^./,,;s/${ext}$//" | sort | sed "s,^.*$,[\`&\`] (&${ext})," >>${fname}
    cat ${fname}
done
