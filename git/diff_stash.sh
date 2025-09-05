#!/bin/bash -eu
# -----------------------------------------------------------------------------------------------
#
# git/diff_stash.sh
#
# PURPOSE:
#
# METHOD:
#
# USAGE:
#
# Feb 2024 JCL
#
# -----------------------------------------------------------------------------------------------

# get starting time in nanoseconds
declare -i start_time=$(date +%s%N)

# set debug level
# substitue default value if DEBUG is unset or null
declare -i DEBUG=${DEBUG:-0}

# load bash utilities
fpretty="${HOME}/config/.bashrc_pretty"
if [ -e "${fpretty}" ]; then
	source "${fpretty}"
	print_debug
else
	# ignore undefined variables
	set +u
	# do not exit on errors
	set +e
fi

# determine if script is being sourced or executed and add conditional behavior
if (return 0 2>/dev/null); then
	set +e
else
	# exit on errors
	set -e
	set_traps
fi
print_source

# load git utils
for library in git; do
	# use the canonical (physical) source directory for reference; this is important if sourcing
	# this file directly from shell
	fname="${src_dir_phys}/lib_${library}.sh"
	if [ -e "${fname}" ]; then
		if [[ "$-" == *i* ]] && [ ${DEBUG:-0} -gt 0 ]; then
			echo "${TAB}loading $(basename "${fname}")"
		fi
		source "${fname}"
	else
		echo "${fname} not found"
	fi
done

cbar "${BOLD}check directory...${RESET}"
if ! check_repo 1; then
	echo -e "${DIR}$PWD${RESET} is not a Git repository"
	exit 1
fi

# get root dir
repo_dir=$(git rev-parse --show-toplevel)
echo -e "${TAB}repository directory is ${PSDIR}${repo_dir}${RESET}"
# get repo name
repo=${repo_dir##*/}
echo "${TAB}repository name is $repo"
# get git dir
GITDIR=$(readlink -f "$(git rev-parse --git-dir)")
echo -e "${TAB}the git-dir folder is ${PSDIR}${GITDIR##*/}${RESET}"
# cd to repo root dir
if [[ ${PWD} -ef ${repo_dir} ]]; then
	echo "${TAB}already in top level directory"
else
	echo "${TAB}$PWD is part of a Git repository"
	echo "${TAB}moving to top level directory..."
	cd -L "$repo_dir"
	echo "${TAB}$PWD"
fi

parse_remote_tracking_branch

function check_min() {
	# Validate input - ensure tot is numeric and not empty
	if [[ -z "$tot" ]] || [[ ! "$tot" =~ ^[0-9]+$ ]]; then
		echo "Warning: Invalid total value: '$tot'" >&2
		return 1
	fi

	# Initialize n_min if not set
	if [ -z "${n_min+dummy}" ]; then
		n_min=$tot
		hash_min=("$hash") # Initialize as array
	fi

	# Ensure n_min is also numeric
	if [[ ! "$n_min" =~ ^[0-9]+$ ]]; then
		n_min=$tot
		hash_min=("$hash")
	fi

	if [ "$tot" -le "$n_min" ]; then
		[ "$i_count" -gt 0 ] && echo
		echo -n "${TAB}$hash: "
		echo -n "$tot +/- changes "

		if [ "$tot" -eq "$n_min" ]; then
			# Check if hash is already in array
			local hash_exists=false
			for existing_hash in "${hash_min[@]}"; do
				if [[ "$existing_hash" == "$hash" ]]; then
					hash_exists=true
					break
				fi
			done

			if ! $hash_exists; then
				hash_min+=("$hash")
			fi
			echo "same min"
		else
			# New minimum found
			hash_min=("$hash") # Reset array with new hash
			echo "new min"
			itab
			if git diff --color=always --ignore-space-change --stat "${hash}" "${stash}" -- "$fname" 2>/dev/null; then
				git diff --color=always --ignore-space-change --stat "${hash}" "${stash}" -- "$fname" | sed "s/^/$TAB/"
			else
				echo "${TAB}Error: Could not generate diff" >&2
			fi
			dtab
		fi

		# update value of n_min
		n_min=$tot
	else
		[ "$i_count" -eq 0 ] && echo -n "${TAB}"
		((++i_count))
		if [ $((i_count % 10)) -eq 0 ]; then
			echo ". $i_count"
			echo -n "${TAB}"
		else
			echo -n "."
		fi
	fi
}

function loop_hosts() {
	echo "${TAB}${cmd}"

	# Validate git command exists and repository is valid
	if ! git rev-parse --git-dir >/dev/null 2>&1; then
		echo "Error: Not in a git repository" >&2
		return 1
	fi

	local n_rev
	if ! n_rev=$($cmd 2>/dev/null | wc -l); then
		echo "Error: Failed to execute git command: $cmd" >&2
		return 1
	fi

	echo "${TAB}$n_rev revisions found"

	local -i i_count=0
	local -i tot=0

	# Process each hash from the git command
	while IFS= read -r hash; do
		[[ -z "$hash" ]] && continue # Skip empty lines

		# Get numstat output and handle potential errors
		local numstat_output
		if ! numstat_output=$(git diff --ignore-space-change --numstat "${hash}" "${stash}" -- "$fname" 2>/dev/null); then
			echo "Warning: Could not get diff stats for $hash" >&2
			continue
		fi

		# Parse add/sub values with proper error handling
		local add sub
		if [[ -n "$numstat_output" ]]; then
			add=$(echo "$numstat_output" | awk '{print $1}')
			sub=$(echo "$numstat_output" | awk '{print $2}')
		else
			add="0"
			sub="0"
		fi

		# Handle binary files and non-numeric values
		# Check if file is binary
		if git diff --ignore-space-change --numstat "${hash}" "${stash}" -- "$fname" 2>&1 | grep -q "^-\s\+-\s\+"; then
			echo "${TAB}Warning: $fname appears to be a binary file (hash: $hash)" >&2
		fi
		if [[ "$add" == "-" ]] || [[ ! "$add" =~ ^[0-9]+$ ]]; then
			add=0
		fi

		if [[ "$sub" == "-" ]] || [[ ! "$sub" =~ ^[0-9]+$ ]]; then
			sub=0
		fi

		# Calculate total with error handling
		if ! tot=$((add + sub)); then
			echo "Warning: Could not calculate total changes for $hash" >&2
			continue
		fi

		# exit loop if zero changes found
		if [ "$tot" -eq 0 ]; then
			check_min
			break
		fi

		# Limit iterations to prevent infinite loops
		if [ "$i_count" -gt 15 ]; then
			echo "Warning: Reached maximum iteration limit" >&2
			break
		fi

		check_min

	done < <($cmd 2>/dev/null)

	[ "$n_rev" -gt 0 ] && [ "$tot" -gt 0 ] && echo -e "\x1B[17G done"
	echo
}

#check_remotes

# check for stash entries
cbar "${BOLD}parsing stash...${RESET}"
N_stash=$(git stash list | wc -l)

if [ $N_stash -gt 1 ]; then
	echo -e "${TAB}$repo has $N_stash entries in stash"
	do_cmd_stdbuf git stash list
	cbar "${BOLD}looking for duplicate stashes...${RESET}"

	# loop over stash entries
	loop_lim=$(($N_stash - 1))
	for ((n = 0; n < loop_lim; n++)); do
		echo "n = $n (start)"
		# check entries
		N_stash_in=$(git stash list | wc -l)

		if [ $N_stash_in = $N_stash ]; then
			echo "no change in number of stash entries ($N_stash_in)"
		else
			echo "number of stash entries has changed"
			echo "$repo now has $N_stash_in entries in stash"

			# check limit
			echo "old loop limit = $loop_lim"
			new_lim=$((N_stash_in - 1))
			echo "new limit should be $new_lim"
			if [ $n -ge $new_lim ]; then
				echo "new limit exceeded"
				echo "breaking..."
				break
			fi
		fi

		stash="stash@{$n}"
		next="stash@{$(($n + 1))}"
		cmd="git diff --ignore-space-change --stat $stash $next"
		echo $cmd
		if [ $DEBUG -gt 0 ]; then
			$cmd
		fi

		# check if empty
		if [ -z "$(git diff --ignore-space-change --stat $stash $next 2>&1)" ]; then
			# print commit
			echo "${stash} $next"
			git log -1 ${stash}
			echo
			echo -e "${BAD}EMPTY: no diff"

			# remove duplicate stash
			git stash drop ${stash}
			# decrement counter
			((--n))
			echo -en "${RESET}"
		fi
		echo "n = $n (end)"
	done
fi

# update stash list
N_stash=$(git stash list | wc -l)
if [ $N_stash -gt 0 ]; then
	echo -e "${TAB}repo has $N_stash entries in stash"

	if [ -z "$@" ]; then
		n_start=0
	else
		n_start=$1
	fi

	if [ $n_start -ge $N_stash ]; then
		echo -e "${TAB}${BAD}cannot diff stash@{$1}${RESET}"
		itab
		echo -e "${TAB}user argument: ${ARG}$1${RESET}"
		echo "${TAB}stash only has $N_stash entries"
		echo "${TAB}exiting..."
		dtab
		exit 1
	fi

	echo
	cbar "${BOLD}checking stash entry ${n_start}...${RESET}"

	# loop over stash entries
	for ((n = $n_start; n < ((n_start + 1)); n++)); do
		stash="stash@{$n}"
		echo "${TAB}${stash}"
		do_cmd_in git log -1 ${stash}
		echo

		# get names of stashed files
		cmd="git diff --ignore-space-change --name-only ${stash}^ ${stash}"
		echo "${TAB}$cmd"
		do_cmd_in $cmd

		# Initialize arrays properly
		stash_files=()
		diff_files=()
		declare -i n_diff_files=0

		# Check if stash has any changes
		stash_output=""
		if ! stash_output=$(eval "$cmd" 2>/dev/null) || [ -z "$stash_output" ]; then
			# check if stash is empty
			echo -e "${BAD}EMPTY: no diff"
			echo "stash@{$n} has no diff"
			if git stash drop "stash@{$n}" 2>/dev/null; then
				echo "${TAB}Successfully dropped empty stash"
			else
				echo "${TAB}Warning: Could not drop stash" >&2
			fi
			echo -en "${RESET}"
			continue
		else
			# Read files into array safely
			while IFS= read -r fil; do
				[[ -n "$fil" ]] && stash_files+=("$fil")
			done < <(eval "$cmd" 2>/dev/null)
		fi

		# list stashed files
		echo "${TAB}stashed files: "
		itab
		n_stash_files=${#stash_files[@]}
		echo "${TAB}$n_stash_files files found"
		echo -en "${YELLOW}"
		echo "${stash_files[@]}" | sed "s/ /\n/g" | sed "s/^/${TAB}/"
		echo -en "${RESET}"
		dtab

		cbar "${BOLD}looping over files in stash@{$n}...${RESET}"

		# loop over stashed files
		# track total changes
		tot=""
		for fname in "${stash_files[@]}"; do
			echo -e "${TAB}${YELLOW}$fname${RESET}..."
			itab
			# Initialize variables properly
			n_min=""
			hash_min=()
			i_count=0

			# get list of hashes before stash that contain file
			cmd="git rev-list ${stash}^ -- $(printf '%q' "$fname")"
			loop_hosts

			# get list of hashes not found in stash, up to HEAD, that contain file
			cmd="git rev-list HEAD^ ^${stash}^ -- $(printf '%q' "$fname")"
			loop_hosts

			echo "${TAB}minimum diff:"
			itab
			if [[ -n "${n_min:-}" ]]; then
				echo "${TAB}$n_min +/- changes"
			else
				echo -e "${TAB}${RED}No minimum found${RESET}"
			fi

			# Display hash information safely
			if [[ ${#hash_min[@]} -gt 0 ]]; then
				for hash in "${hash_min[@]}"; do
					if git rev-parse --verify "$hash" >/dev/null 2>&1; then
						echo -n "${TAB}$(git log --color=always -n 1 --format="%C(auto)%H%d %ad" "$hash" 2>/dev/null) "
						echo -e "$(git log --color=always -n 1 --relative-date --format="%Cblue%ad" "$hash" 2>/dev/null)${RESET}"
					fi
				done
			fi

			dtab

			# Check if minimum changes is zero (changes already committed)
			if [[ -n "${n_min:-}" ]] && [ "$n_min" -eq 0 ]; then
				if [ "$n_stash_files" -eq 1 ]; then
					echo "${TAB}dropping stash@{$n}..."
					do_cmd_in git stash drop "stash@{$n}"
					continue 2
				fi
				echo -e "${TAB}${BOLD}${GREEN}stashed changes saved in commits${RESET}"
				dtab
			else
				# Add file to diff list if changes exist
				diff_files+=("$fname")
				((++n_diff_files))

				echo "${TAB}displaying minimum diff:"
				itab
				echo -e "${TAB}${RED}-removed by stash@{$n}${RESET}"
				echo -e "${TAB}${GREEN}+  added by stash@{$n}${RESET}"

				# Use first hash from minimum set for diff
				if [[ ${#hash_min[@]} -gt 0 ]]; then
					first_hash="${hash_min[0]}"
					cmd="git --no-pager diff --color=always --color-moved=blocks --ignore-space-change $(printf '%q' "$first_hash") $stash -- $(printf '%q' "$fname")"
					echo "${TAB}$cmd"
					dtab
					if ! do_cmd "$cmd"; then
						echo "${TAB}Warning: Could not display diff" >&2
					fi
				else
					if git diff --ignore-space-change --numstat "${first_hash}" "${stash}" -- "$fname" 2>&1 | grep -q "^-\s\+-\s\+"; then
						echo "${TAB}Note: $fname appears to be a binary file (hash: $first_hash)"
					else
						echo "${TAB}Warning: No hash available for diff" >&2
					fi
					dtab
				fi
				dtab
			fi

		done # files

		# list diff files
		echo
		echo "${TAB}diff files: "
		itab
		if [ ${n_diff_files} -eq 0 ]; then
			echo "${TAB}none"
			echo "${TAB}dropping stash@{$n}..."
			do_cmd_in git stash drop stash@{$n}
			continue
		fi

		echo "${TAB}$n_diff_files files found"
		echo -en "${YELLOW}"
		echo "${diff_files[@]}" | sed "s/ /\n/g" | sed "s/^/${TAB}/"
		echo -en "${RESET}"
		dtab

		echo "${TAB}to delete, use"
		itab
		echo "${TAB}git stash drop stash@{$n}"
		dtab
		echo
	done # stash entreis
	dtab
	echo "${TAB}done"
else
	echo "no stash entries found"
fi
echo
set_exit
