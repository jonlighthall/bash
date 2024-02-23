#!/bin/bash -u
#
# git/check_repos.sh
#
# METHOD -
#
# USAGE - the remote name and branch can be optionally specified by the first and second
# arguments, respectively. The default remote branch is the current tracking branch.
#
# Apr 2023 JCL

# get starting time in nanoseconds
declare -i start_time=$(date +%s%N)

# set tab
: ${TAB:=''}
: ${fTAB:='   '}

# set debug level
declare -i DEBUG=0

# load formatting and functions
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
	source $fpretty
	set_traps
fi

# determine if script is being sourced or executed and add conditional behavior
if (return 0 2>/dev/null); then
	RUN_TYPE="sourcing"
	set -T +e
else
	RUN_TYPE="executing"
fi

# list SSH status
host_OK=''

# bad hosts
echo -n "bad hosts: "
if [ -z "$host_bad" ]; then
	echo "none"
else
	host_bad=$(echo "${host_bad}" | sort -n)
	echo
	echo -e "${BAD}${host_bad}${NORMAL}" | sed "s/^/${fTAB}/"
fi


host_bad=''

# get number of remotes
n_remotes=$(git remote | wc -l)
r_names=$(git remote)
if [ "${n_remotes}" -gt 1 ]; then
	echo "remotes found: ${n_remotes}"
else
	echo -n "remote: "
fi
declare -i i=0
for remote_name in ${r_names}; do
	if [ "${n_remotes}" -gt 1 ]; then
		((++i))
		echo -n "${TAB}${fTAB}$i) "
		TAB+=${fTAB:='   '}
	fi
	echo "$remote_name"
	remote_url=$(git remote get-url ${remote_name})
	echo "${TAB}${fTAB}  url: ${remote_url}"
	# parse protocol
	remote_pro=$(echo ${remote_url} | sed 's/\(^[^:@]*\)[:@].*$/\1/')
	if [[ "${remote_pro}" == "git" ]]; then
		remote_pro="SSH"
		remote_host=$(echo ${remote_url} | sed 's/\(^[^:]*\):.*$/\1/')
	else
		remote_host=$(echo ${remote_url} | sed 's,^[a-z]*://\([^/]*\).*,\1,')
		if [[ "${remote_pro}" == "http"* ]]; then
			# warn about HTTP remotes
			remote_pro=${GRH}${remote_pro}${NORMAL}
			remote_repo=$(echo ${remote_url} | sed 's,^[a-z]*://[^/]*/\(.*\),\1,')
			echo "  repo: ${remote_repo}"
			# change remote to SSH
			remote_ssh="git@${remote_host}:${remote_repo}"
			echo " change URL to ${remote_ssh}..."
			echo " ${fTAB}git remote set-url ${remote_name} ${remote_ssh}"
			git remote set-url ${remote_name} ${remote_ssh}						
		else
			remote_pro="local"
		fi							
	fi	
	echo "${TAB}${fTAB} host: $remote_host"
  	echo -e "${TAB}${fTAB}proto: ${remote_pro}"
	if [[ "${remote_pro}" == "SSH" ]]; then
		# default to checking host
		do_check=true
		decho "do_check = $do_check"

		# check remote host name against list of checked hosts
		if [ ! -z ${host_OK:+dummy} ]; then
			decho "checking $remote_host against list of checked hosts"
			for good_host in ${host_OK}; do
				if [[ $remote_host =~ $good_host ]]; then
					decho "$remote_host matches $good_host"
					do_check=false
					break
				else
					continue
				fi
			done
		else
			decho "list of checked hosts empty"
		fi
		decho "do_check = $do_check"

		# check connection before proceeding
		if [ ${do_check} = 'true' ]; then
			echo -n "${TAB}${fTAB}checking connection... "
			unset_traps
			ssh -o ConnectTimeout=1 -o ConnectionAttempts=1 -T ${remote_host}
			RETVAL=$?
			set_traps
			if [[ $RETVAL == 0 ]]; then
				echo -e "${TAB}${fTAB}${GOOD}OK${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
				# add to list
				if [ ! -z ${host_OK:+dummy} ]; then
					host_OK+=$'\n'
				fi
				host_OK+=${remote_host}
			else
				if [[ $RETVAL == 1 ]]; then
					echo -e "${TAB}${fTAB}${yellow}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
					if [[ $remote_host =~ "github.com" ]]; then
						decho "host is github"
						# Github will return 1 if everything is working
						# add to list
						if [ ! -z ${host_OK:+dummy} ]; then
							host_OK+=$'\n'
						fi
						host_OK+=${remote_host}
					else
						decho "host is not github"
						# add to list
						if [ ! -z ${host_bad:+dummy} ]; then
							host_bad+=$'\n'
						fi
						host_bad+=${remote_host}
					fi
				else
					echo -e "${TAB}${fTAB}${BAD}FAIL${NORMAL} ${gray}RETVAL=$RETVAL${NORMAL}"
					# add to list
					if [ ! -z ${host_bad:+dummy} ]; then
						host_bad+=$'\n'
					fi
					host_bad+=${remote_host}
				fi
			fi
		fi
	fi
	if [ "${n_remotes}" -gt 1 ]; then
		TAB=${TAB%$fTAB}
	fi
done
unset remote_url
unset remote_pro
unset remote_host

# bad hosts
echo -n "bad hosts: "
if [ -z "$host_bad" ]; then
	echo "none"
else
	host_bad=$(echo "${host_bad}" | sort -n)
	echo
	echo -e "${BAD}${host_bad}${NORMAL}" | sed "s/^/${fTAB}/"
fi

export host_bad

echo "done"
# add return code for parent script
return 0
