#~/bin/bash
find -L ./ -not -path "*/.git*/*" -type f | sed '/.sh$/!d;s%^./%%;s/.sh$//;/\//d' | sort | sed 's/.*/| [`&`](&.sh) |/' > ls.txt; cat ls.txt
