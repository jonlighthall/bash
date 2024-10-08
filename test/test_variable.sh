#!/bin/bash -u
#
# test_variable.sh - test the value of a variable. expected values are null, true, false
#
# after checking variable status, perform all bash tests and print values
#
# Jul 2023 JCL

# load bash utilities
fpretty=${HOME}/config/.bashrc_pretty
if [ -e $fpretty ]; then
	  source $fpretty
fi

print_source

# define conditions and anti-conditions
c1="${UNSET} or ${NULL}"
a1="set and not null"
c2="set and ${NULL}"
a2="${UNSET} or not null"
c3="${UNSET}"
a3="set or ${NULL}"

clear -x

# check if sourced
if (return 0 2>/dev/null); then
	  echo "script is sourced"
else
	  echo -e "${GRH}CAUTION: script has not been sourced. Results may not reflect current shell.${RESET}"
fi

function bool_test() {
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
}

function pbool_test() {
    echo -e "----------------------------------------------------"
		# true/false
		echo "pseudo-boolean tests"
		echo -e "----------------------------------------------------"
		# NB [] tests must include a comparison, otherwise any non-null (including false) will test as true
		echo "comparison tests"
		if ! [[ "${!VAR}" =~ " " ]]; then
				echo -e -n "[  ${VAR}  =   true  ] : " # fails when unset or null (condition 1): unary operator expected
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
				echo -e -n "[  ${VAR}  =  'true' ] : " # fails when unset or null (condition 1): unary operator expected
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

}

function var_stat() {
    echo -e "${INVERT}${FUNCNAME} start${RESET}"
    clear -x

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
			          # CONDITION 2: true when VAR is null
			          if [ -z ${!VAR-default} ]; then
				            echo -e " ${TRUE}: ${NULL}"
				            echo -e "\n\E[1m${VAR} is ${c2}\E[0m"
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

	      if [ ! -z ${!VAR+alternate} ]; then  # set
		        if [ ! -z "${!VAR-default}" ]; then # not null
                bool_test
                pbool_test
		        fi
	      fi

    done

    echo -e "${INVERT}${FUNCNAME} done${RESET}"

}

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

    var_stat $VAR

	  if ! [[ "${!VAR}" =~ " " ]]; then
		    echo -e "----------------------------------------------------"
		    # null tests, no quotes
		    # all [ -z ] tests are false when VAR is set
		    echo "no quotes"
		    echo -e "----------------------------------------------------"

		    #---------------
		    # no substition
		    #---------------

		    (
			      echo -ne "NULL [ -z \${VAR   } ]>"
			      # CONDITION 1: true when VAR is unset or null
			      if [ -z ${!VAR} ]; then
				        echo -ne " ${TRUE}>${c1}"
			      else
				        echo -ne "${FALSE}>${a1}"
			      fi
			      echo ">'${!VAR}'"

			      #-----------------------------------
			      # substitute unset VAR with default
			      #-----------------------------------

			      echo -ne "NULL [ -z \${VAR-d } ]>"
			      # CONDITION 2: true when VAR is null
			      if [ -z ${!VAR-default} ]; then
				        echo -ne " ${TRUE}>${c2}"
			      else
				        echo -ne "${FALSE}>"
				        if [[ ${!VAR-default} == default ]]; then
					          echo -ne "${UNSET}"
				        else
					          echo -n "${a1}"
				        fi
			      fi
			      # substitution occurs when VAR is unset (has not been declared)
			      echo ">'${!VAR:-default}'"

			      echo -ne "NULL [ -z \${VAR:-d} ]>"
			      # CONDITION 1: true when VAR is unset or null and default is null (impossible with text)
			      if [ -z ${!VAR:-default} ]; then
				        echo -ne " ${TRUE}>${c1}"
			      else
				        echo -ne "${FALSE}>"
				        if [[ ${!VAR:-default} == default ]]; then
					          echo -ne "${c1}"
				        else
					          echo -n "${a1}"
				        fi
			      fi
			      # substitution occurs when VAR is unset (has not been declared) or null (empty)
			      echo ">'${!VAR:-default}'"

			      #-----------------------------------
			      # substitute set VAR with alternate
			      #-----------------------------------

			      echo -ne "NULL [ -z \${VAR+a } ]>"
			      # CONDITION 3: true when VAR is unset
			      if [ -z ${!VAR+alternate} ]; then
				        echo -ne " ${TRUE}>${c3}"
			      else
				        echo -ne "${FALSE}>${a3}"
			      fi
			      # substitution occurs when VAR is set or null
			      echo ">'${!VAR+alternate}'"

			      echo -ne "NULL [ -z \${VAR:+a} ]>"
			      # CONDITION 1: true if VAR is unset or null
			      if [ -z ${!VAR:+alternate} ]; then
				        echo -ne " ${TRUE}>${c1}"
			      else
				        echo -ne "${FALSE}>${a1}"
			      fi
			      # substitution occurs when VAR is set and not null
			      echo ">'${!VAR:+alternate}'"

		        # not null, no quotes
			      echo -ne "NOT NULL [ ! -z \${VAR} ]>"
			      if [ ! -z ${!VAR} ]; then
				        echo -e " ${TRUE}>${a1}"
			      else
				        echo -e "${FALSE}>${c1}"
			      fi

			      echo -ne "NOT NULL [ ! -z \${VAR-d} ]>"
			      if [ ! -z ${!VAR-default} ]; then
				        echo -e " ${TRUE}>${a2}"
			      else
				        echo -e "${FALSE}>${c2}"
			      fi

			      echo -ne "NOT NULL [ ! -z \${VAR:-d} ]>"
			      if [ ! -z ${!VAR:-default} ]; then
				        echo -e " ${TRUE}>${a2}"
			      else
				        echo -e "${FALSE}>${c2}"
			      fi

			      echo -ne "NOT NULL [ ! -z \${VAR+a} ]>"
			      if [ ! -z ${!VAR+alternate} ]; then
				        echo -e " ${TRUE}>${a3}"
			      else
				        echo -e "${FALSE}>${UNSET}"
			      fi

			      echo -ne "NOT NULL [ ! -z \${VAR:+}]>"
			      if [ ! -z ${!VAR:+alternate} ]; then
				        echo -e " ${TRUE}>${a1}"
			      else
				        echo -e "${FALSE}>${c1}"
			      fi
		    ) | column -t -s '$' -o '$' -R 1 | column -t -s '>' -o ' : '
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
		    echo -e " ${TRUE}: ${a2}"
	  else
		    echo -e "${FALSE}: ${c2}"
	  fi

	  echo -ne "NOT NULL (-n :- \"\")	: "
	  if [ -n "${!VAR:-default}" ]; then
		    echo -e " ${TRUE}: ${a2}"
	  else
		    echo -e "${FALSE}: ${c2}"
	  fi

	  echo -ne "NOT NULL (-n + \"\")	: "
	  if [ -n "${!VAR+alternate}" ]; then
		    echo -e " ${TRUE}: ${a3}"
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
	  # CONDITION 1: true when VAR is unset or null
	  if [ ! -n "${!VAR}" ]; then
		    echo -e " ${TRUE}: ${c1}"
	  else
		    echo -e "${FALSE}: ${a1}"
	  fi

	  echo -ne "    NULL (! -n - \"\")	: "
	  # CONDITION 2: true when VAR is null
	  if [ ! -n "${!VAR-default}" ]; then
		    echo -e " ${TRUE}: ${c2}"
	  else
		    echo -e "${FALSE}: ${a2}"
	  fi

	  echo -ne "    NULL (! -n :- \"\")   : "
	  # CONDITION 2: true when VAR is null
	  if [ ! -n "${!VAR:-default}" ]; then
		    echo -e " ${TRUE}: ${c2}"
	  else
		    echo -e "${FALSE}: ${a2}"
	  fi

	  echo -ne "    NULL (! -n + \"\")	: "
	  if [ ! -n "${!VAR+alternate}" ]; then
		    echo -e " ${TRUE}: ${UNSET}"
	  else
		    echo -e "${FALSE}: ${a3}"
	  fi

	  echo -ne "    NULL (! -n :+ \"\")   : "
	  # CONDITION 1: true when VAR is unset or null
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
	  # CONDITION 3: true when VAR is unset
	  if [ ! -z "${!VAR+alternate}" ] && [ -n "${!VAR+alternate}" ]; then
		    echo -e " ${TRUE}: ${a3}"
	  else
		    echo -e "${FALSE}: ${c3}"
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
	  # CONDITION 1: true when VAR is unset or null
	  if [ -z "${!VAR}" ] && [ ! -n "${!VAR}" ]; then
		    echo -e " ${TRUE}: ${c1}"
	  else
		    echo -e "${FALSE}: ${a1}"
	  fi

	  echo -ne "    NULL (-z && ! -n + \"\")  : "
	  # CONDITION 3: true when VAR is unset
	  if [ -z "${!VAR+alternate}" ] && [ ! -n "${!VAR+alternate}" ]; then
		    echo -e " ${TRUE}: ${c3}"
	  else
		    echo -e "${FALSE}: ${a3}"
	  fi

	  echo -ne "    NULL (-z && ! -n :+ \"\") : "
	  # CONDITION 1: true when VAR is unset or null
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
        echo "practical"
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
