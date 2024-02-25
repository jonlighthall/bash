#!/bin/bash -u
#
# ls2md.sh - convert directory contents to markdown links. Used for creating a
# table of contents for git readme files. Optional argument specifies the file
# extenstion. Default is '.sh'
#
# Jun 2023 JCL

# parse arguments
if [ $# -eq 0 ]; then
    echo "No argument specified. Using default"
    arg=".sh"
else
    echo "Specified argument = $@"
    arg=$@
fi

# set output file name
fname=ls2md.md

# print current directory
echo -e "# Contents of $(pwd)\n" >${fname}

# loop through each argument
for ext in $arg; do
    echo "filtering $arg"
    echo -e "## ${ext} files\n" >>${fname}
    find -L ./ -not -path "*/.git*/*" -type f -name "*${ext}" | sed "s,^./,,;s/${ext}$//" | sort | sed "s,^.*$,[\`&\`](&${ext})," >>${fname}
done

# save root directories to file
echo -e "\n## Directories\n" >>${fname}
find -L ./ -not -path "*/.git*" -not -path "*/.vscode*" -type d | sed 's,^./,,;/\//d;/^$/d' | sort | sed "s,^.*$,[\`&\`](&)," >>${fname}

echo "done"

# print contents of file
echo "Contents of ${fname}:"
cat ${fname} | sed "s/^/   /"