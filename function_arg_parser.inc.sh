#!/usr/bin/env bash

function example
{
	local user=__REQUIRED__
	local port=22
	local sudo=0
	local verbose=0
	local argvars=( user port sudo verbose )
	local remains=()

	while test -n "$1"; do
		eval '
		case $1 in
			-u | --user )    shift; user=$1  ;; # username
			-p | --port )    shift; port=$1  ;; # port [22]
			-s | --sudo )    sudo=1          ;; # sudo to root
			-v          )    verbose=1       ;; # verbose
			-h | --help )    usage; return   ;; # usage
			* )              remains+=("$1")
		esac
		shift
		'
	done

	for varname in "${argvars[@]}"; do
		(( verbose )) && echo "$varname: ${!varname}"
		if [ "${!varname}" == "__REQUIRED__" ]; then
			echo "Missing required option '${varname}'"
			usage
			return
		fi
	done
}

function usage
{
	local caller=${FUNCNAME[1]}
	local regex
	local args options comment
   regex='(.*))(.*)#(.*)'
	while read -r line; do
		if [[ $line =~ $regex ]]; then
			printf "[%s] [%s] [%s]\n" "${BASH_REMATCH[@]:1}"
			list 3 args options comment "${BASH_REMATCH[@]:1}"
			eval trim\ {args,options,comment}\;
			# trim args
			# trim options
			# trim comment
			printf "(%s) (%s) (%s)\n" $args $options $comment
			set +x xtrace
		fi
	done < <( declare -f "$caller" )
}

function trim
{
	# this is a hacky trim, it will also remove extra whitespace from
	# inside the string
	local s v t;
	v=$1;
	s=${!v};
	explode2 "${s}" $'\x20\x09' "t"
	s="${t[*]}"
	echo "trum: '$s'"
}

function list
{
	# usage: data=( big red ball ); list 3 size color toy "${data[@]}"
	local count=$1; shift
	local vars=()
	local loop 
	
	for (( loop=0; loop<count; loop++ )); do vars+=("$1"); shift; done
	for (( loop=0; loop<count; loop++ )); do printf -v "${vars[$loop]}" "%s" "$1"; shift; done
}

function explode2
{
   local string=${1:-} && shift
   local delim=${1:- } && shift
   local array_name=${1:-EXPLODED} && shift
   IFS="$delim" read -a "$array_name" <<<"$string";
}

if [[ ${BASH_SOURCE[@]} == $0 ]]; then example; fi
