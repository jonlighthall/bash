# print source name at start
if (return 0 2>/dev/null); then
    RUN_TYPE="sourcing"
else
    RUN_TYPE="executing"
fi
echo -e "${RUN_TYPE} $BASH_SOURCE..."

function get_start() {
	# get starting time in nanoseconds
	export start_time=$(date +%s%N)
}

function timestamp() {
	echo "$(date +"%a %b %-d at %-l:%M %p %Z")"
}

function print_elap() {
	declare -i end_time=$(date +%s%N)
	if [ -n "${start_time+alt}" ]; then
		declare -i elap_time=$((${end_time} - ${start_time}))
		if command -v bc &>/dev/null; then
			dT_sec=$(bc <<<"scale=9;$elap_time/10^9" | sed 's/^\./0./')
		else
			dT_sec=${elap_time::-9}.${elap_time:$((${#elap_time}-9))}
			if [ ${#elap_time} -eq 9 ];then
				dT_sec=$(echo "0.$elap_time")
			fi
		fi
		# set scale
		declare -ir nd=3
		fmt="%.${nd}f"
		dT_sec=$(printf "$fmt" $dT_sec)
	else
		echo -ne "start_time not defined "
		dT_sec=-1
	fi
	
	if command -v sec2elap &>/dev/null; then
		bash sec2elap $dT_sec | tr -d "\n"
	else
		echo -ne "elapsed time is ${dT_sec} sec"
	fi
}

function print_exit() {
	# optional argument is $?
	# e.g.
	# trap 'print_exit $?' EXIT

	# parse arguments
	if [ $# -gt 0 ]; then
		EXIT_RETVAL=$1
	fi

	start_new_line
	echo -ne "\E[7m EXIT \E[0m "
	# print exit code
	if [ ! -z ${EXIT_RETVAL+alt} ]; then
		echo -ne "RETVAL=${EXIT_RETVAL} "
	fi
	echo -e "${0##*/}"
	
	print_elap
	echo -n " on "
	timestamp
}

function start_new_line() {
	# get the cursor position
	echo -en "\E[6n"
	read -sdR CURPOS
	CURPOS=${CURPOS#*[}
			 # get the x-position of the cursor
			 x_pos=${CURPOS#*;}
			 # if the cursor is not at the start of a line, then create a new line
			 if [ ${x_pos} -gt 1 ]; then
				 echo
			 fi
		  }

# define traps
function set_traps() {
	if [ -z "${DEBUG+alt}" ]; then
		DEBUG=0
	fi
	echo -e "\E[7mset traps\E[0m"

	# determine if script is being sourced or executed and add conditional behavior
	echo -n "setting shell options for... "
	# trace RETURN and DEBUG traps
	#		set -T
	if (return 0 2>/dev/null); then
		export RUN_TYPE="sourcing"
		# do NOT exit on errors
		#		set +e
		# trace RETURN and DEBUG traps
		#		set -T
	else
		export RUN_TYPE="executing"
		# exit on errors
		set -e
	fi
	echo -e "\E[7m${RUN_TYPE}\E[0m"
	# trace ERR traps
	set -E
	echo "the following traps are saved"
	if [ -z "${save_traps+default}" ]; then
		echo "none"
		echo -n "setting traps... "
		trap 'print_error $LINENO $? $BASH_COMMAND' ERR
		trap 'print_exit $?' EXIT
		echo "done"
	else
		echo "${save_traps}" | sed "s/^//"
		echo "setting saved traps..."
		eval $(echo "${save_traps}" | sed "s/$/;/g")
	fi

	# print summary
	echo "on set trap retrun, the following traps are set"
	if [ -z "$(trap -p)" ]; then
		echo -e "none"
		exit
	else
		echo -e "$(trap -p | sed 's/^/   /')" 
	fi
}

function unset_traps() {
	echo -e "\E[7mun-set traps\E[0m"
	echo "setting shell options..."
	set +eE

	echo -n "the current traps are set"
	if [ -z "$(trap -p)" ]; then
		echo -e "\nnone"
	else
		echo $(trap -p) | sed "s/^//;s/ \(trap\)/\n\1/g" | sed 's/^[ ]*$//g'

		# save traps
		export save_traps=$(trap -p | sed 's/-- //g')
		if [ ! -z "${save_traps}" ]; then
			echo "the current traps are saved"
			echo "${save_traps}" | sed "s/^//"
		fi

		# clear traps
		trap - ERR
		trap - EXIT
		trap - RETURN
	fi

	# print summary
	echo "on unset trap retrun, the following traps are set"
	if [ -z $(trap -p) ]; then
		echo "none"
	else
		echo $(trap -p)
		exit
	fi
}
