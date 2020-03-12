#!/usr/bin/env bash

# __INCLUDER_DIRNAME="$( cd "$( dirname $0 )" && pwd -P )"
# printf "DIRNAME: %s\n" $__INCLUDER_DIRNAME
# declare -p | grep includer
# echo 0:$0

# unset __INCLUDER_DIRNAME
unset require_once

function shutup_cd
{
	builtin cd "$@" > /dev/null 2>/dev/null
}

# http://stackoverflow.com/questions/64786/error-handling-in-bash/18118450#18118450
warning()
{
    # Output warning messages
    # Color the output red if it's an interactive terminal
    # @param $1...: Messages

    test -t 1 && tput setf 4

    printf '%s\n' "$@" >&2

    test -t 1 && tput sgr0 # Reset terminal
    true
}

error()
{
    # Output error messages with optional exit code
    # @param $1...: Messages
    # @param $N: Exit code (optional)

    messages=( "$@" )

    # If the last parameter is a number, it's not part of the messages
    last_parameter="${messages[@]: -1}"
    if [[ "$last_parameter" =~ ^[0-9]*$ ]]
    then
        exit_code=$last_parameter
        unset messages[$((${#messages[@]} - 1))]
    fi

    warning "${messages[@]}"

    exit ${exit_code:-$EX_UNKNOWN}
}

if declare -F require_once > /dev/null; then
	echo require_once includer... cached > /dev/null
else
	__DEBUG=COMMENT_TO_UNSET

	decho() {
		test -z "$__DEBUG" && return
		echo "$@"
	} >&2

	includer__in_array() {													 # duplicate of function from arrays.inc.sh - we want everything self contained here.
		needle="$1"
		shift

		while [ $# -gt 0 ]; do
			if [ "$needle" == "$1" ]; then
				return 0
			fi
			shift
		done
		return 1
	}

	require_once() {
		local __dirname
		local __basename
		local __found
		local src
		local tried
		local __failcount=0

		while [ -n "$1" ]; do
			src="$1"
			shift

			__dirname="$( dirname "$src" )"
			__basename="$( basename "$src" )"
			__noext="${__basename%.inc.*}"
			__noext="${__noext%.sh}"


			if includer__in_array "$__basename" "${__INCLUDED_SCRIPTS[@]}"; then
				continue
			fi


			__found=0
			tried=()
			for fn in "$src" {.,"$__dirname","$__INCLUDER_DIRNAME"}/"$__noext"{,.sh,.inc.sh,.class.sh,.class.inc.sh}; do
				tried+=("$fn"$'\n')
				if [ -f "$fn" ]; then
					__found=1
					__INCLUDED_SCRIPTS+=("$__basename")
					pushd . > /dev/null
					cd "$( dirname "$fn" )"
					decho "Including $fn" 
					source "$fn"
					popd > /dev/null
					break															 # stop looking for the file now
				fi
			done
			(( ! __found )) \
				&& decho "Required include file not found: \"$src\" not found; path: ${__INCLUDER_DIRNAME}" \
				&& (( __failcount++ ))
		done
		# array check
		return $__failcount
	} >&2

		
	unset __INCLUDER_DIRNAME

	# http://stackoverflow.com/questions/630372/determine-the-path-of-the-executing-bash-script
	# echo 
	# printf '%16s %s\n' '$0' $0
	# printf '%16s %s\n' '$BASH_SOURCE[0..]' "${BASH_SOURCE[@]}"
	# echo
	# prg="$( command -v -- "$0" )"

	# __target=$( readlink "${BASH_SOURCE[0]}" )
	# declare -p | grep bash
	# set -o xtrace


	## realpath
	# http://stackoverflow.com/a/246128/912236
	SOURCE=${BASH_SOURCE[0]}
	# SOURCE=${1:-$SOURCE} # Allow argument for testing, or to be run as stand alone util 
	while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
	  DIR=$( cd -P "$( dirname "$SOURCE" )" && pwd )
	  SOURCE=$(readlink "$SOURCE")
	  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
	done
	REALPATH=$( cd -P "$( dirname "$SOURCE" )" && pwd )

	# prg=$( command -v -- "${BASH_SOURCE[0]}" )
	# echo "** prg: $prg"
	# realpath=$( realpath "$prg" )
	# echo "** realpath: $realpath"
	# dir=$( dirname -- "$realpath" )
	# echo "** dir: $dir"
	dir=$REALPATH
	export __INCLUDER_DIRNAME=$dir

	declare -a __INCLUDED_SCRIPTS='("includer.inc.sh")'
fi >&2

(( $# > 0 )) && require_once "$@"
# vim: set ts=3 sts=64 sw=3 foldmethod=marker noet:
