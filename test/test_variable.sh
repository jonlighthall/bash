#!/bin/bash -u
#
# test_variable.sh - test the value of a variable. expected values are null, true, false
#
# Jul 2023 JCL

# set tab
called_by=$(ps -o comm= $PPID)
if [ "${called_by}" = "bash" ] || [ "${called_by}" = "SessionLeader" ]; then
	TAB=''
	: ${fTAB:='   '}
else
	TAB+=${TAB+${fTAB:='   '}}
fi

# load formatting and functions
fpretty=${HOME}/utils/bash/.bashrc_pretty
if [ -e $fpretty ]; then
	source $fpretty
fi

# print source name at start
if (return 0 2>/dev/null); then
	RUN_TYPE="sourcing"
else
	RUN_TYPE="executing"
fi
echo -e "${TAB}${RUN_TYPE} ${PSDIR}$BASH_SOURCE${NORMAL}..."
src_name=$(readlink -f $BASH_SOURCE)
if [ ! "$BASH_SOURCE" = "$src_name" ]; then
	echo -e "${TAB}${VALID}link${NORMAL} -> $src_name"
fi

# define colors
TRUE='\E[1;32mtrue\E[0m'
FALSE='\E[1;31mfalse\E[0m'
UNSET='\E[1;33munset\E[0m'
NULL='\E[1;36mnull\E[0m'

clear -x

# check if sourced
if (return 0 2>/dev/null); then
	echo "script is sourced"
else
	echo "CAUTION: script has not been sourced. Results may not reflect current shell."
fi

# parse inputs
if [ $# -eq 0 ]; then
	echo "no input received"
	echo "possibilities:"
	echo "   - no argument given"
	echo "   - value passed (e.g. \$VB) instead of name (e.g. VB) and:"
	echo -e "      - input is ${UNSET}"
	echo -e "      - input is ${NULL}"
	if ! (return 0 2>/dev/null); then
		echo "   - input is not exported"
	fi
	echo "using default argument"
	input=VB
else
	echo -n "argument"
	if [ $# -gt 1 ]; then
		echo -n "s"
	fi
	echo ": $@ "
	input=$@
fi

echo -n "testing variable"
if [ $# -gt 1 ]; then
	echo -n "s"
fi
echo " $input..."

# test inputs
for VAR in $input; do
	echo
	echo -n "testing VAR: ${VAR} = "

	# NB when using indirect reference, the parameter must be in brackets
	# check if VAR is set
	if [ -z ${!VAR+alternate} ]; then
		echo -e "${UNSET}"
		set +u
	else
		echo "'${!VAR}'"
	fi

	if [[ "${VAR}" == "${!VAR}" ]]; then
		echo "value of variable name matches FOR loop variable name"
		break
	fi

	echo -e "----------------------------------------------------"
	# what is it?
	#echo -e "----------------------------------------------------"
	echo -n "is ${VAR} set    : "
	if [ ! -z ${!VAR+alternate} ]; then
		echo -e " ${TRUE}: set"
		echo -n "${VAR} has space : "
		if [[ "${!VAR}" =~ " " ]]; then
			echo -e " ${TRUE}: contains whitespace"
		else
			echo -e "${FALSE}: does not contain whitespace"
			echo -n "is ${VAR} null   : "
			if [ -z ${!VAR-default} ]; then
				echo -e " ${TRUE}: ${NULL}"
				echo -e "\n\E[1m${VAR} is set and ${NULL}\E[0m"
			else
				echo -e "${FALSE}: not null"
				echo -n "is ${VAR} boolean: "
				if [ ${!VAR} = true ] || [ ${!VAR} = false ]; then
					echo -e " ${TRUE}"
					echo -n "is ${VAR} true   : "
					if ${!VAR}; then # fails when what
						echo -e " ${TRUE}"
						echo -e "\n\E[1m${VAR} is set and ${TRUE}"
					else
						echo -e "${FALSE}"
						echo -e "\n\E[1m${VAR} is set and ${FALSE}"
					fi
				else
					echo -e "${FALSE}: not boolean"
					echo -n "is ${VAR} integer: "
					if [[ "${!VAR}" =~ ^[0-9]+$ ]]; then
						echo -e " ${TRUE}: integer"
						echo -e "\n\E[1m${VAR} is set and an integer\E[0m"
					else
						echo -e "${FALSE}: not integer"
						echo -e "\n\E[1m${VAR} is set and not boolean or integer\E[0m"
					fi
				fi
			fi
		fi
	else
		echo -e "${FALSE}: ${UNSET}"
		echo -e "\n\E[1m${VAR} is ${UNSET}"
	fi

	if [ ! -z ${!VAR+alternate} ]; then    # set
		if [ ! -z "${!VAR-default}" ]; then # not null
			echo -e "----------------------------------------------------"
			# true/false
			echo "pseudo-boolean tests"
			echo -e "----------------------------------------------------"
			# NB [] tests must include a comparison, otherwise any non-null (including false) will test as true
			echo "comparison tests"
			if ! [[ "${!VAR}" =~ " " ]]; then
				echo -e -n "[  ${VAR}  =   true  ] : " # fails when unset or null: unary operator expected
				if [ ${!VAR} = true ]; then
					echo -e " ${TRUE}"
				else
					echo -e "${FALSE}"
				fi

				echo -e -n "[  ${VAR}  =  false  ] : "
				if [ ${!VAR} = false ]; then
					echo -e " ${TRUE}"
				else
					echo -e "${FALSE}"
				fi

				# literal
				echo -e -n "[  ${VAR}  =  'true' ] : " # fails when unset or null: unary operator expected
				if [ ${!VAR} = 'true' ]; then
					echo -e " ${TRUE}"
				else
					echo -e "${FALSE}"
				fi

				echo -e -n "[  ${VAR}  = 'false' ] : "
				if [ ${!VAR} = 'false' ]; then
					echo -e " ${TRUE}"
				else
					echo -e "${FALSE}"
				fi

				#string
				echo -e -n "[  ${VAR}  =  \"true\" ] : "
				if [ ${!VAR} = "true" ]; then
					echo -e " ${TRUE}"
				else
					echo -e "${FALSE}"
				fi

				echo -e -n "[  ${VAR}  = \"false\" ] : "
				if [ ${!VAR} = "false" ]; then
					echo -e " ${TRUE}"
				else
					echo -e "${FALSE}"
				fi
			fi

			echo -e -n "[ \"${VAR}\" =   true  ] : "
			if [ "${!VAR}" = true ]; then
				echo -e " ${TRUE}"
			else
				echo -e "${FALSE}"
			fi

			echo -e -n "[ \"${VAR}\" =  false  ] : "
			if [ "${!VAR}" = false ]; then
				echo -e " ${TRUE}"
			else
				echo -e "${FALSE}"
			fi

			# string
			echo -e -n "[ \"${VAR}\" =  \"true\" ] : "
			if [ "${!VAR}" = "true" ]; then
				echo -e " ${TRUE}"
			else
				echo -e "${FALSE}"
			fi

			echo -e -n "[ \"${VAR}\" = \"false\" ] : "
			if [ "${!VAR}" = "false" ]; then
				echo -e " ${TRUE}"
			else
				echo -e "${FALSE}"
			fi

			if [ "${!VAR}" = true ] || [ "${!VAR}" = false ]; then # boolean
				echo "boolean tests"
				# the following conditionals will fail when non-boolean: command not found
				echo -e -n "  ${VAR}  : "
				if ${!VAR}; then
					echo -e " ${TRUE}"
				else
					echo -e "${FALSE}"
				fi

				echo -e -n " !${VAR}  : "
				if ! ${!VAR}; then
					echo -e " ${TRUE}"
				else
					echo -e "${FALSE}"
				fi

				echo -e -n " \"${VAR}\" : "
				if "${!VAR}"; then
					echo -e " ${TRUE}"
				else
					echo -e "${FALSE}"
				fi

				echo -e -n "!\"${VAR}\" : "
				if ! "${!VAR}"; then
					echo -e " ${TRUE}"
				else
					echo -e "${FALSE}"
				fi
			fi
		fi
	fi

	if ! [[ "${!VAR}" =~ " " ]]; then
		echo -e "----------------------------------------------------"
		# null tests, no quotes
		# all [ -z ] tests are false when VAR is set
		echo "no quotes"
		echo -e "----------------------------------------------------"
		echo -ne "    NULL [ -z \${VAR   } ]\t: "
		# true when VAR is unset or null
		c1="${UNSET} or ${NULL}"
		a1="set and not null"
		if [ -z ${!VAR} ]; then
			echo -ne " ${TRUE}: ${c1}"
		else
			echo -ne "${FALSE}: ${a1}"
		fi
		echo -e "\t: '${!VAR}'"

		echo -ne "    NULL [ -z \${VAR-d } ]\t: "
		# only true when VAR is null
		if [ -z ${!VAR-default} ]; then
			echo -ne " ${TRUE}: set and ${NULL}"
		else
			echo -ne "${FALSE}: "
			if [[ ${!VAR-default} == default ]]; then
				echo -ne "${UNSET}\t"
			else
				echo -n "${a1}"
			fi
		fi
		# substitution occurs when VAR is unset (has not been declared)
		echo -e "\t: '${!VAR:-default}'"

		echo -ne "    NULL [ -z \${VAR:-d} ]\t: "
		# only true when VAR is (unset or null) and default is null (impossible with text)
		if [ -z ${!VAR:-default} ]; then
			echo -ne " ${TRUE}: ${c1}"			
		else
			echo -ne "${FALSE}: "
			if [[ ${!VAR:-default} == default ]]; then
				echo -ne "${c1}"
			else
				echo -n "${a1}"
			fi
		fi
		# substitution occurs when VAR is unset (has not been declared) or null (empty)
		echo -e "\t: '${!VAR:-default}'"
		
		echo -ne "    NULL [ -z \${VAR+a } ]\t: "
		# only true when VAR is unset
		if [ -z ${!VAR+alternate} ]; then
			echo -ne " ${TRUE}: ${UNSET}\t"
		else
			echo -ne "${FALSE}: set (maybe null)"
		fi
		# substitution occurs when VAR is set or null
		echo -e "\t: '${!VAR+alternate}'"

		echo -ne "    NULL [ -z \${VAR:+a} ]\t: "
		# true if VAR is unset or null
		if [ -z ${!VAR:+alternate} ]; then
			echo -ne " ${TRUE}: ${c1}"
		else
			echo -ne "${FALSE}: ${a1}"
		fi
		# substitution occurs when VAR is set and not null
		echo -e "\t: '${!VAR:+alternate}'"

		# not null, no quotes
		echo -e "----------------------------------------------------"
		echo -ne "NOT NULL (! -z)       : "
		if [ ! -z ${!VAR} ]; then
			echo -e " ${TRUE}: ${a1}"
		else
			echo -e "${FALSE}: ${c1}"
		fi

		echo -ne "NOT NULL (! -z -)     : "
		if [ ! -z ${!VAR-default} ]; then
			echo -e " ${TRUE}: ${UNSET} or not null"
		else
			echo -e "${FALSE}: ${NULL}"
		fi

		echo -ne "NOT NULL (! -z :-)    : "
		if [ ! -z ${!VAR:-default} ]; then
			echo -e " ${TRUE}: ?? ${UNSET} or not null"
		else
			echo -e "${FALSE}: ?? ${NULL}"
		fi

		echo -ne "NOT NULL (! -z +)     : "
		if [ ! -z ${!VAR+alternate} ]; then
			echo -e " ${TRUE}: set (maybe null)"
		else
			echo -e "${FALSE}: ${UNSET}"
		fi

		echo -ne "NOT NULL (! -z :+)    : "
		if [ ! -z ${!VAR:+alternate} ]; then
			echo -e " ${TRUE}: ${a1}"
		else
			echo -e "${FALSE}: ${c1}"
		fi
	fi

	echo -e "----------------------------------------------------"
	# not null, quotes
	# NB -n arguments must be in quotes
	echo "quotes"
	echo -e "----------------------------------------------------"
	echo -ne "NOT NULL (-n \"\")        : "
	if [ -n "${!VAR}" ]; then
		echo -e " ${TRUE}: ${a1}"
	else
		echo -e "${FALSE}: ${c1}"
	fi

	echo -ne "NOT NULL (-n - \"\")	: "
	if [ -n "${!VAR-default}" ]; then
		echo -e " ${TRUE}: ${UNSET} or not null"
	else
		echo -e "${FALSE}: ${NULL}"
	fi

	echo -ne "NOT NULL (-n :- \"\")	: "
	if [ -n "${!VAR:-default}" ]; then
		echo -e " ${TRUE}: ?? ${UNSET} or not null"
	else
		echo -e "${FALSE}: ?? ${NULL}"
	fi

	echo -ne "NOT NULL (-n + \"\")	: "
	if [ -n "${!VAR+alternate}" ]; then
		echo -e " ${TRUE}: set (maybe null)"
	else
		echo -e "${FALSE}: ${UNSET}"
	fi

	echo -ne "NOT NULL (-n :+ \"\")	: "
	if [ -n "${!VAR:+alternate}" ]; then
		echo -e " ${TRUE}: ${a1}"
	else
		echo -e "${FALSE}: ${c1}"
	fi

	# not not null, quotes
	echo -e "----------------------------------------------------"
	echo -ne "    NULL (! -n \"\")	: "
	if [ ! -n "${!VAR}" ]; then
		echo -e " ${TRUE}: ${c1}"
	else
		echo -e "${FALSE}: ${a1}"
	fi

	echo -ne "    NULL (! -n - \"\")	: "
	if [ ! -n "${!VAR-default}" ]; then
		echo -e " ${TRUE}: ${NULL}"
	else
		echo -e "${FALSE}: ${UNSET} or not null"
	fi

	echo -ne "    NULL (! -n :- \"\")   : "
	if [ ! -n "${!VAR:-default}" ]; then
		echo -e " ${TRUE}: ??${NULL}"
	else
		echo -e "${FALSE}: ??${UNSET} or not null"
	fi

	echo -ne "    NULL (! -n + \"\")	: "
	if [ ! -n "${!VAR+alternate}" ]; then
		echo -e " ${TRUE}: ${UNSET}"
	else
		echo -e "${FALSE}: set (maybe null)"
	fi

	echo -ne "    NULL (! -n :+ \"\")   : "
	if [ ! -n "${!VAR:+alternate}" ]; then
		echo -e " ${TRUE}: ${c1}"
	else
		echo -e "${FALSE}: ${a1}"
	fi
	echo -e "----------------------------------------------------"
	# not null ands, quotes
	# NB -n arguments must be in quotes
	echo "ands"
	echo -e "----------------------------------------------------"
	echo -ne "NOT NULL (! -z && -n \"\")    : "
	if [ ! -z "${!VAR}" ] && [ -n "${!VAR}" ]; then
		echo -e " ${TRUE}: ${a1}"
	else
		echo -e "${FALSE}: ${c1}"
	fi

	echo -ne "NOT NULL (! -z && -n + \"\")  : "
	if [ ! -z "${!VAR+alternate}" ] && [ -n "${!VAR+alternate}" ]; then
		echo -e " ${TRUE}: set (maybe null)"
	else
		echo -e "${FALSE}: ${UNSET}"
	fi

	echo -ne "NOT NULL (! -z && -n :+ \"\") : "
	if [ ! -z "${!VAR:+alternate}" ] && [ -n "${!VAR:+alternate}" ]; then
		echo -e " ${TRUE}: ${a1}"
	else
		echo -e "${FALSE}: ${c1}"
	fi

	# null ands, quotes
	echo -e "----------------------------------------------------"
	echo -ne "    NULL (-z && ! -n \"\")    : "
	if [ -z "${!VAR}" ] && [ ! -n "${!VAR}" ]; then
		echo -e " ${TRUE}: ${c1}"
	else
		echo -e "${FALSE}: ${a1}"
	fi

	echo -ne "    NULL (-z && ! -n + \"\")  : "
	if [ -z "${!VAR+alternate}" ] && [ ! -n "${!VAR+alternate}" ]; then
		echo -e " ${TRUE}: ${UNSET}"
	else
		echo -e "${FALSE}: set (maybe null)"
	fi

	echo -ne "    NULL (-z && ! -n :+ \"\") : "
	if [ -z "${!VAR:+alternate}" ] && [ ! -n "${!VAR:+alternate}" ]; then
		echo -e " ${TRUE}: ${c1}"
	else
		echo -e "${FALSE}: ${a1}"
	fi

	echo -e "----------------------------------------------------"
	# impossible and
	# NB -n arguments must be in quotes
	echo "impossible"
	echo -e "----------------------------------------------------"
	echo -ne "    NULL and NOT NULL (-z && -n \"\")     : "
	if [ -z "${!VAR}" ] && [ -n "${!VAR}" ]; then
		echo -e " ${TRUE}: impossible!"
	else
		echo -e "${FALSE}: OK"
	fi

	echo -ne "NOT NULL and	 NULL (! -z && ! -n \"\") : "
	if [ ! -z "${!VAR}" ] && [ ! -n "${!VAR}" ]; then
		echo -e " ${TRUE}: impossible!"
	else
		echo -e "${FALSE}: OK"
	fi
	echo -e "----------------------------------------------------"

	# practical tests
	if ! [[ "${!VAR}" =~ " " ]]; then
		echo -e "----------------------------------------------------"
		echo -ne "    not unset (set): "
		if [ ! -z ${!VAR+alternate} ]; then
			echo -e " ${TRUE}"
		else
			echo -e "${FALSE}"
		fi

		echo -ne "not unset and  true: "
		if [ ! -z ${!VAR:+alternate} ] && [ ${!VAR} = true ]; then
			echo -e " ${TRUE}" # fails when what
		else
			echo -e "${FALSE}"
		fi

		echo -ne "not unset and false: "
		if [ ! -z ${!VAR:+alternate} ] && [ ${!VAR} = false ]; then
			echo -e " ${TRUE}" # fails when what
		else
			echo -e "${FALSE}"
		fi

		# NB -n arguments must be in quotes
		echo -ne "      set and  true: "
		if [ -n "${!VAR:+alternate}" ] && [ ${!VAR} = true ]; then
			echo -e " ${TRUE}"
		else
			echo -e "${FALSE}"
		fi

		echo -ne "      set and false: "
		if [ -n "${!VAR:+alternate}" ] && [ ${!VAR} = false ]; then
			echo -e " ${TRUE}"
		else
			echo -e "${FALSE}"
		fi
	fi
done
