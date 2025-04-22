#!/bin/bash -u

# load bash utilities
fpretty="${HOME}/config/.bashrc_pretty"
if [ -e "$fpretty" ]; then
    source "$fpretty"
fi

# set shell options
if [[ "$-" == *e* ]]; then
    # exit on errors must be turned off; otherwise shell will exit broken links
    # are found
    old_opts=$(echo "$-")
    set +e
fi
unset_traps

# check for input
if [ $# -eq 0 ]; then
	  echo "Please provide a list of files"
    get_source
    echo -e "${TAB}EXAMPLE${RESET}"
    itab
    echo -e "${TAB}${BOLD}find -L ./ -type l | xargs ${src_dir_logi}/${src_base}${RESET}"
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

                # remove broken link
                echo "${TAB}deleting $arg..."
                rm -v ${arg} | sed "s/^/${TAB}/"
                dtab
			      fi
		    fi
	  done
fi

reset_shell ${old_opts-''}
reset_traps
