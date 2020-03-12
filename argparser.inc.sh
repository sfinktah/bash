#!/usr/bin/env bash

# Updates to this script may be found at
# http://nt4.com/bash/argparser.inc.sh

# Example of runtime usage:
# mnc.sh --nc -q Caprica.S0*mkv *.avi *.mp3 --more-options here --host centos8.host.com

# Example of use in script (see bottom)
# Just include this file in yours, or use
# source argparser.inc.sh

unset EXPLODED
declare -a EXPLODED
function explode 
{
	local c=$# 
	(( c < 2 )) && 
	{
		echo function "$0" is missing parameters 
		return 1
	}

	local delimiter="$1"
	local string="$2"
	local limit=${3-99}

	local tmp_delim=$'\x07'
	local delin=${string//$delimiter/$tmp_delim}
	local oldifs="$IFS"

	IFS="$tmp_delim"
	EXPLODED=($delin)
	IFS="$oldifs"
}


# See: http://fvue.nl/wiki/Bash:_Passing_variables_by_reference
# Usage: local "$1" && upvar $1 "value(s)"
upvar() {
    if unset -v "$1"; then           # Unset & validate varname
        if (( $# == 2 )); then
            eval $1=\"\$2\"          # Return single value
        else
            eval $1=\(\"\${@:2}\"\)  # Return array
        fi
    fi
}

function decho
{
	:
}

function ArgParser::check
{
	__args=${#__argparser__arglist[@]}
	for (( i=0; i<__args; i++ ))
	do
		matched=0
		explode "|" "${__argparser__arglist[$i]}"
		if [ "${#1}" -eq 1 ]
		then
			if [ "${1}" == "${EXPLODED[0]}" ]
			then
				decho "Matched $1 with ${EXPLODED[0]}"
				matched=1

				break
			fi
		else
			if [ "${1}" == "${EXPLODED[1]}" ]
			then
				decho "Matched $1 with ${EXPLODED[1]}"
				matched=1

				break
			fi
		fi
	done
	(( matched == 0 )) && return 2
	# decho "Key $key has default argument of ${EXPLODED[3]}"
	if [ "${EXPLODED[3]}" == "false" ]
	then
		return 0
	else
		return 1
	fi
}

function ArgParser::set
{
	key=$3
	value="${1:-true}"
	declare -g __argpassed__$key="$value" ||
	local "__argpassed__$key" && upvar "__argpassed__$key" "$value"
	# eval \"__argpassed__\$key\"=\"$value\"
}

function ArgParser::parse
{

	unset __argparser__argv
	__argparser__argv=()
	# echo parsing: "$@"

	while [ -n "$1" ]
	do
		# echo "Processing $1"
		if [ "${1:0:2}" == '--' ]
		then
			key=${1:2}
			value=$2
		elif [ "${1:0:1}" == '-' ]
		then
			key=${1:1}               # Strip off leading -
			value=$2
		else
			decho "Not argument or option: '$1'" >& 2
			__argparser__argv+=( "$1" )
			shift
			continue
		fi
		# parameter=${tmp%%=*}     # Extract name.
		# value=${tmp##*=}         # Extract value.
		decho "Key: '$key', value: '$value'"
		# eval $parameter=$value
		ArgParser::check $key
		el=$?
		# echo "Check returned $el for $key"
		[ $el -eq  2 ] && decho "No match for option '$1'" >&2 # && __argparser__argv+=( "$1" )
		[ $el -eq  0 ] && decho "Matched option '${EXPLODED[2]}' with no arguments"	       >&2 && ArgParser::set true "${EXPLODED[@]}"
		[ $el -eq  1 ] && decho "Matched option '${EXPLODED[2]}' with an argument of '$2'"   >&2 && ArgParser::set "$2" "${EXPLODED[@]}" && shift
		shift
	done
}

function ArgParser::isset
{
	## Determine if a variable is set and is not NULL.

	local varname
	decho "ArgParser::isset($1)"
	declare -p "__argpassed__$1" > /dev/null 2>&1 || return 1
	varname="__argpassed__$1"
	decho "Checking isset(${!varname}): "
	test -n "${!varname}" || return 1
	return 0
}

function ArgParser::is_string
{
	local varname
	local value
	varname="__argpassed__$1"
	value="${!varname}"


	test -n "${!varname}"
}

function ArgParser::required
{
	ArgParser::isset "$1" || {
		echo "Missing required parameter '$1', try --help for help."
		exit 1
	}
}


function ArgParser::empty
{
	test -n "${__argpassed__$1}"
}

function ArgParser::getArg
{
	# This one would be a bit silly, since we can only return non-integer arguments ineffeciently
	varname="__argpassed__$1"
	echo "${!varname}"
}

##
# usage: tryAndGetArg <argname> into <varname>
# returns: 0 on success, 1 on failure
function ArgParser::tryAndGetArg
{
	local __varname="__argpassed__$1"
	local __value="${!__varname}"
	test -z "$__value" && return 1
	local "$3" && upvar $3 "$__value"
	return 0
}

function ArgParser::__construct
{
	unset __argparser__arglist
	# declare -a __argparser__arglist
}

##
# @brief add command line argument
# @param 1 short and/or long, eg: [s]hort
# @param 2 default value
# @param 3 description
##
function ArgParser::addArg
{
	regex="\[(.)\]"
	# check for short arg within long arg
	if [[ "$1" =~ $regex ]]
	then
		short=${BASH_REMATCH[1]}
		long=${1/\[$short\]/$short}
	else
		long=$1
	fi
	if [ "${#long}" -eq 1 ]
	then
		short=$long
		long=''
	fi
	decho short: "$short"
	decho long: "$long"
	__argparser__arglist+=("$short|$long|$1|$2|$3")
}

## 
# @brief show available command line arguments
##
function ArgParser::showArgs
{
	# declare -p | grep argparser
	printf "Usage: %s [OPTION...]\n\n" "$( basename "${BASH_SOURCE[0]}" )"
	printf "Defaults for the options are specified in brackets.\n\n";

	__args=${#__argparser__arglist[@]}
	for (( i=0; i<__args; i++ ))
	do
		local shortname=
		local fullname=
		local default=
		local description=
		local comma=

		explode "|" "${__argparser__arglist[$i]}"

		shortname="${EXPLODED[0]:+-${EXPLODED[0]}}"	# String Substitution Guide: 
		fullname="${EXPLODED[1]:+--${EXPLODED[1]}}"	# http://tldp.org/LDP/abs/html/parameter-substitution.html
		test -n "$shortname" \
			&& test -n "$fullname" \
			&& comma=","

		default="${EXPLODED[3]}"
		case $default in
			false )
				default=
				;;
			"" )
				default=
				;;
			* )
				default="[$default]"
		esac

		description="${EXPLODED[4]}"

		printf "  %2s%1s %-19s %s %s\n" "$shortname" "$comma" "$fullname" "$description" "$default"
	done
	echo
}

function ArgParser::test
{
	# Arguments with a default of 'false' do not take paramaters (note: default
	# values are not applied in this release)

	ArgParser::addArg "[h]elp"		false		"This list"
	ArgParser::addArg "[q]uiet"	false		"Supress output"
	ArgParser::addArg "[s]leep"	1			"Seconds to sleep"
	ArgParser::addArg "v"			1			"Verbose mode"

	ArgParser::parse "$@"

	ArgParser::isset help && ArgParser::showArgs

	ArgParser::isset "quiet" \
		&& echo "Quiet!" \
		|| echo "Noisy!"

	local __sleep
	ArgParser::tryAndGetArg sleep into __sleep \
		&& echo "Sleep for $__sleep seconds" \
		|| echo "No value passed for sleep"

	# This way is often more convienient, but is a little slower
	echo "Sleep set to: $( ArgParser::getArg sleep )"

	echo "Remaining command line: ${__argparser__argv[@]}"

	ArgParser::required hell

}

if [ "$( basename "$0" )" == "argparser.inc.sh" ]
then
	ArgParser::test "$@"
fi
