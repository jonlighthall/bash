#!/bin/bash -u

# load bash utilities
fpretty="${HOME}/config/.bashrc_pretty"
if [ -e "$fpretty" ]; then
    source "$fpretty"
fi

# set shell options
if [[ "$-" == *e* ]]; then
    # exit on errors must be turned off; otherwise shell will exit no remote branch found
    old_opts=$(echo "$-")
    set +e
fi
unset_traps

# check for input
if [ $# -eq 0 ]; then
	  echo "Please provide a list of files"
    get_source
    echo "example: find -L ./ \( -type l -o -xtype l \) | xargs ${src_dir_logi}/${src_base}"
else
	  # check arguments
	  for arg in "$@"; do
		    if [ -L "${arg}" ]; then
			      if [ ! -e "${arg}" ]; then
                echo -en "${YELLOW}$arg${RESET} "
                echo -n "is a "
				        echo -e -n "${BROKEN}broken${RESET}"
			          echo -e " ${UL}link${RESET}"
                ls -l --color ${arg} | sed 's,^.*\(\./\),\1,'

                og_fname=$(echo ${arg} | sed 's/_[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}-t[0-9]\{6\}//')
                echo -n "${TAB}${og_fname}..."

                itab
                if [ -e "${og_fname}" ]; then
                    echo "exists"
                    echo "${TAB}deleting $arg..."
                    rm -v ${arg} | sed "s/^/${TAB}/"
                else
                    echo "not found"
                fi
                dtab
			      fi
		    fi
	  done
fi

reset_shell ${old_opts-''}
reset_traps
