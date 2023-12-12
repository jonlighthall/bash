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
    echo "   - value passed (e.g. \$VB) instead of name (e.g. VB)"
    echo -e "      - input is $UNSET"
    echo "      - input is null"

    if ! (return 0 2>/dev/null); then
	echo "   - input is not exported"
    fi
    echo "using default argument"
    input=VB
else
    echo "arguments: $@"
    input=$@
fi

echo "testing variables $input..."

# test inputs
for VAR in $input
do
    echo
    echo "testing VAR: ${VAR} = '${!VAR}'"

    if [[ "${VAR}" == "${!VAR}" ]]; then
	echo "value of variable name matches FOR loop variable name"
	break
    fi

    echo -e "----------------------------------------------------"
    # what is it?
    echo -e "----------------------------------------------------"
    echo -n "is ${VAR} set    : "
    if [ ! -z ${!VAR+dummy} ]; then
	echo -e " ${TRUE}: set"
	echo -n "is ${VAR} null   : "
	if [ -z ${!VAR-dummy} ]; then
	    echo -e " ${TRUE}: null (empty)"
	    echo -e "\n\E[1m${VAR} is set and null\E[0m"
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
		echo -e "\n\E[1m${VAR} is set and not boolean"
	    fi
	fi
    else
	echo -e "${FALSE}: ${UNSET}"
	echo -e "\n\E[1m${VAR} is ${UNSET}"
    fi
    echo -e "----------------------------------------------------"

    # true/false
    echo -e "----------------------------------------------------"

    if [ ! -z ${!VAR+dummy} ]; then # set
	if [ ! -z ${!VAR-dummy} ]; then # not null
	    # NB when using indirect reference, the parameter must be in brackets
	    echo -e -n "    brackets [] t : " # fails when unset or null: unary operator expected
	    if [ ${!VAR} = 'true' ]; then
		echo -e " ${TRUE}"
	    else
		echo -e "${FALSE}"
	    fi

	    echo -e -n "   no quotes [] t : " # fails when unset or null: unary operator expected
	    if [ ${!VAR} = true ]; then
		echo -e " ${TRUE}"
	    else
		echo -e "${FALSE}"
	    fi

	    if [ ${!VAR} = true ] || [ ${!VAR} = false ]; then # boolean
		# NB when using indirect reference, the parameter must be in brackets
		echo -e -n "         brackets : " # true when unset or null; fails when non-boolean: command not found
		if ${!VAR}; then
		    echo -e " ${TRUE}"
		else
		    echo -e "${FALSE}"
		fi

		echo -e -n "           quotes : " # fails when unset or null or non-boolean: command not found
		if "${!VAR}"; then
		    echo -e " ${TRUE}"
		else
		    echo -e "${FALSE}"
		fi
	    fi
	fi
    fi

    # NB [] tests must include a comparison, otherwise any non-null (including false) will test as true
    echo -e -n "      quotes [] t : "
    if [ "${!VAR}" = "true" ]; then
	echo -e " ${TRUE}"
    else
	echo -e "${FALSE}"
    fi

    echo -e -n " quotes [] t bare : "
    if [ "${!VAR}" = true ]; then
	echo -e " ${TRUE}"
    else
	echo -e "${FALSE}"
    fi

    # practical tests
    echo -e "----------------------------------------------------"
    echo -e -n "   not unset (set): "
    if [ ! -z ${!VAR+dummy} ]; then
	echo -e " ${TRUE}"
    else
	echo -e "${FALSE}"
    fi

    echo -e -n "not unset\E[0m and true\E[0m: "
    if [ ! -z ${!VAR:+dummy} ] && [ ${!VAR} = true ]; then
	echo -e " ${TRUE}" # fails when what
    else
	echo -e "${FALSE}"
    fi

    # NB -n arguments must be in quotes
    echo -e -n "      set and true: "
    if [ -n "${!VAR:+dummy}" ] && [ ${!VAR} = true ]; then
	echo -e " ${TRUE}"
    else
	echo -e "${FALSE}"
    fi

    echo -e -n "     set and false: "
    if [ -n "${!VAR:+dummy}" ] && [ ${!VAR} = false ]; then
	echo -e " ${TRUE}"
    else
	echo -e "${FALSE}"
    fi

    echo -e "----------------------------------------------------"
    # null, no quotes
    echo -e "----------------------------------------------------"
    echo -e -n "    NULL (-z)         : "
    if [ -z ${!VAR} ]; then
	echo -e " ${TRUE}: ${UNSET} or null (empty)"
    else
	echo -e "${FALSE}: set and not null"
    fi

    echo -e -n "    NULL (-z -)       : "
    if [ -z ${!VAR-dummy} ]; then
	echo -e " ${TRUE}: set and null (empty)"
    else
	echo -e "${FALSE}: ${UNSET} or not null"
    fi

    echo -e -n "    NULL (-z :-)      : "
    if [ -z ${!VAR:-dummy} ]; then
	echo -e " ${TRUE}: ?? ${UNSET}"
	# set and null, different than -
    else
	echo -e "${FALSE}: ?? set and not null"
	# unset - false, same as -

	# set not null - false
    fi

    echo -e -n "    NULL (-z +)       : "
    if [ -z ${!VAR+dummy} ]; then
	echo -e " ${TRUE}: ${UNSET}"
    else
	echo -e "${FALSE}: set (maybe null)"
    fi

    echo -e -n "    NULL (-z :+)      : "
    if [ -z ${!VAR:+dummy} ]; then
	echo -e " ${TRUE}: ${UNSET} or null"
    else
	echo -e "${FALSE}: set and not null"
    fi

    # not null, no quotes
    echo -e "----------------------------------------------------"
    echo -e -n "NOT NULL (! -z)       : "
    if [ ! -z ${!VAR} ]; then
	echo -e " ${TRUE}: not null"
    else
	echo -e "${FALSE}: ${UNSET} or null"
    fi

    echo -e -n "NOT NULL (! -z -)     : "
    if [ ! -z ${!VAR-dummy} ]; then
	echo -e " ${TRUE}: ${UNSET} or not null"
    else
	echo -e "${FALSE}: set and null"
    fi

    echo -e -n "NOT NULL (! -z :-)    : "
    if [ ! -z ${!VAR:-dummy} ]; then
	echo -e " ${TRUE}: ?? ${UNSET} or not null"
    else
	echo -e "${FALSE}: ?? set and null"
    fi

    echo -e -n "NOT NULL (! -z +)     : "
    if [ ! -z ${!VAR+dummy} ]; then
	echo -e " ${TRUE}: set (maybe null)"
    else
	echo -e "${FALSE}: ${UNSET}"
    fi

    echo -e -n "NOT NULL (! -z :+)    : "
    if [ ! -z ${!VAR:+dummy} ]; then
	echo -e " ${TRUE}: set and not null"
    else
	echo -e "${FALSE}: ${UNSET} or null"
    fi

    # not null, quotes
    # NB -n arguments must be in quotes
    echo -e "----------------------------------------------------"
    echo -e -n "NOT NULL (-n \"\")      : "
    if [ -n "${!VAR}" ]; then
	echo -e " ${TRUE}: set and not null (empty)"
    else
	echo -e "${FALSE}: ${UNSET} or null"
    fi

    echo -e -n "NOT NULL (-n - \"\")    : "
    if [ -n "${!VAR-dummy}" ]; then
	echo -e " ${TRUE}: ${UNSET} or not null (empty)"
    else
	echo -e "${FALSE}: set and null"
    fi

    echo -e -n "NOT NULL (-n :- \"\")   : "
    if [ -n "${!VAR:-dummy}" ]; then
	echo -e " ${TRUE}: ?? ${UNSET} or not null (empty)"
    else
	echo -e "${FALSE}: ?? set and null"
    fi

    echo -e -n "NOT NULL (-n + \"\")    : "
    if [ -n "${!VAR+dummy}" ]; then
	echo -e " ${TRUE}: set (maybe null)"
    else
	echo -e "${FALSE}: ${UNSET}"
    fi

    echo -e -n "NOT NULL (-n :+ \"\")   : "
    if [ -n "${!VAR:+dummy}" ]; then
	echo -e " ${TRUE}: set and not null"
    else
	echo -e "${FALSE}: ${UNSET} or null"
    fi

    # not not null, quotes
    echo -e "----------------------------------------------------"
    echo -e -n "    NULL (! -n \"\")    : "
    if [ ! -n "${!VAR}" ]; then
	echo -e " ${TRUE}: ${UNSET} or null"
    else
	echo -e "${FALSE}: set and not null"
    fi

    echo -e -n "    NULL (! -n - \"\")  : "
    if [ ! -n "${!VAR-dummy}" ]; then
	echo -e " ${TRUE}: set and null"
    else
	echo -e "${FALSE}: ${UNSET} or not null"
    fi

    echo -e -n "    NULL (! -n :- \"\") : "
    if [ ! -n "${!VAR:-dummy}" ]; then
	echo -e " ${TRUE}: ??set and null"
    else
	echo -e "${FALSE}: ??${UNSET} or not null"
    fi

    echo -e -n "    NULL (! -n + \"\")  : "
    if [ ! -n "${!VAR+dummy}" ]; then
	echo -e " ${TRUE}: ${UNSET}"
    else
	echo -e "${FALSE}: set (maybe null)"
    fi

    echo -e -n "    NULL (! -n :+ \"\") : "
    if [ ! -n "${!VAR:+dummy}" ]; then
	echo -e " ${TRUE}: ${UNSET} or null"
    else
	echo -e "${FALSE}: set and not null"
    fi
    echo -e "----------------------------------------------------"
    # not null ands, quotes
    # NB -n arguments must be in quotes
    echo -e "----------------------------------------------------"
    echo -e -n "NOT NULL (! -z && -n \"\")    : "
    if [ ! -z ${!VAR} ] && [ -n "${!VAR}"  ]; then
	echo -e " ${TRUE}: set and not null"
    else
	echo -e "${FALSE}: ${UNSET} or null"
    fi

    echo -e -n "NOT NULL (! -z && -n + \"\")  : "
    if [ ! -z ${!VAR+dummy} ] && [ -n "${!VAR+dummy}"  ]; then
	echo -e " ${TRUE}: set (maybe null)"
    else
	echo -e "${FALSE}: ${UNSET}"
    fi

    echo -e -n "NOT NULL (! -z && -n :+ \"\") : "
    if [ ! -z ${!VAR:+dummy} ] && [ -n "${!VAR:+dummy}" ]; then
	echo -e " ${TRUE}: set and not null"
    else
	echo -e "${FALSE}: ${UNSET} or null"
    fi

    # null ands, quotes
    echo -e "----------------------------------------------------"
    echo -e -n "    NULL (-z && ! -n \"\")    : "
    if [ -z ${!VAR} ] && [ ! -n "${!VAR}"  ]; then
	echo -e " ${TRUE}: ${UNSET} or null"
    else
	echo -e "${FALSE}: set and not null"
    fi

    echo -e -n "    NULL (-z && ! -n + \"\")  : "
    if [ -z ${!VAR+dummy} ] && [ ! -n "${!VAR+dummy}" ]; then
	echo -e " ${TRUE}: ${UNSET}"
    else
	echo -e "${FALSE}: set (maybe null)"
    fi

    echo -e -n "    NULL (-z && ! -n :+ \"\") : "
    if [ -z ${!VAR:+dummy} ] && [ ! -n "${!VAR:+dummy}" ]; then
	echo -e " ${TRUE}: ${UNSET} or null"
    else
	echo -e "${FALSE}: set and not null"
    fi

    echo -e "----------------------------------------------------"
    # impossible and
    # NB -n arguments must be in quotes
    echo -e "----------------------------------------------------"
    echo -e -n "    NULL and NOT NULL (-z && -n \"\")     : "
    if [ -z ${!VAR} ] && [ -n "${!VAR}"  ]; then
	echo -e " ${TRUE}: impossible!"
    else
	echo -e "${FALSE}: OK"
    fi

    echo -e -n "NOT NULL and     NULL (! -z && ! -n \"\") : "
    if [ ! -z ${!VAR} ] && [ ! -n "${!VAR}"  ]; then
	echo -e " ${TRUE}: impossible!"
    else
	echo -e "${FALSE}: OK"
    fi
    echo -e "----------------------------------------------------"

done
