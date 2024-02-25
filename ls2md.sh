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
echo "Output file = ${fname}"

# print current directory
echo -e "# Contents of $(pwd)\n" >${fname}

# loop through each argument
for ext in $arg; do
    echo "filtering $arg"
    echo -e "## ${ext} files\n" >>${fname}
    find -L ./ -not -path "*/.git*/*" -type f -name "*${ext}" | sed "s,^./,,;s/${ext}$//" | sort | sed "s,^.*$,[\`&\`](&${ext}),;$ ! s,$, \\\\," >>${fname}
done

# save root directories to file
echo -e "\n## Directories\n" >>${fname}
find -L ./ -not -path "*/.git*" -not -path "*/.vscode*" -type d | sed 's,^./,,;/\//d;/^$/d' | sort | sed "s,^.*$,[\`&\`](&),;$ ! s,$, \\\\," >>${fname}

echo "done"

# print contents of file
echo "Contents of ${fname}:"
cat ${fname} | sed "s/^/   /"

# define ignore file
echo
ignore_file=$(pwd)/.gitignore
echo "Checking ${ignore_file}..."
if [ -f ${ignore_file} ]; then
    if grep -q ${fname} ${ignore_file}; then
        echo "${fname} already in ${ignore_file}"
    else
        echo "Adding ${fname} to ${ignore_file}..."
        echo -e "\n#Markdown list" >>${ignore_file}
        echo ${fname} >>${ignore_file}
    fi
else
    echo "Creating ${ignore_file}..."
    echo -e "#Markdown list" >${ignore_file}
    echo ${fname} >>${ignore_file}
fi
