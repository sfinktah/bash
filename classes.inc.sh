#!/usr/bin/env bash
BASEDIR=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)
. ${BASEDIR}/includer.inc.sh upvars

function class {
	this=$1
}

function endclass {
	unset this
}

function forlater {
	while read _x _y _fname 
	do
		# echo method: $_fname
		short_name=${_fname#*.}
		# eval "echo alias $short_name=$_fname"
		# eval "alias $short_name=$_fname"
		# echo "$short_name=$_fname"
		break
	done < <( declare -F | grep "$this" )
	# alias -p
}

function scope {
	local caller=${FUNCNAME[@]:1:1}
	local this && upvar this "${caller%.*}"
	local base && upvar base "${this%.*}"
}

function inherit {
	local parent=$1
	local child=$2
	while read _x _y _fname 
	do
		local short_name=${_fname#*.}
		local lines
		mapfile lines < <( declare -f $_fname )
		lines[0]="$child.$short_name()"
		eval "${lines[@]}"
	done < <( declare -F | grep "${1}\\." )
	# alias -p
}

shopt -s expand_aliases
alias propget='class::getprop "${this}"'
alias propset='class::setprop "${this}"'

class::setprop()
{
	local var="__$1__$2"
	# echo setting "$1::$2" to "$3"
	# echo declare -g $var="$3"
	declare -g $var="$3"
}

class::getprop()
{
	local var="__$1__$2"
	REPLY="${!var}"
	# echo getting "$1::$2" "$REPLY"
	test -n "$3" && 
		local "$3" && 
		upvar $3 "$REPLY"
}

function var
{
	local __lval=${1%%=*}
	local __rval=${1#*=}
	local __class=${__lval%%.*}
	local __varname=${__lval#*.}
	local __full_varname="__${__class}__${__varname}"
	declare -g $__full_varname="${__rval}"
}

# usage: pset class.property=value
# eg:    pset $this.p=$VALUE
function pset
{
	local __lval=${1%%=*}
	local __rval=${1#*=}
	local __class=${__lval%%.*}
	local __varname=${__lval#*.}
	local __full_varname="__${__class}__${__varname}"

	# declare -p | grep __

	declare -g $__full_varname="$__rval"
}
# usage: put class.property into varname
# eg:    put $this.p into REPLY
function put 
{
	local __class=${1%%.*}
	local __varname=${1#*.}
	local __full_varname="__${__class}__${__varname}"
	local __value="${!__full_varname}"
	local "$3" && upvar $3 "$__value"
}

# usage: new classname instancename [ constructor arg1 [ arg2 [ .. ]]]
# eg:    new BinaryString buf
function new
{
	local __classname=$1
	local __varname=$2
	shift 2

	inherit "$__classname" "$__varname"
	$__varname.__construct "$@"
}

# var progress.screen_width
# var progress.max
# var progress.min
# var progress.width
# var progress.value
# 
# function progress.__construct
# {
# 	scope
# 
# 	local __height
# 	local __width
# 
# 	propset min 0
# 	pset progress.min=0
# 	read __height __width < <( stty size )
# 	(( __width -= 15 ))
# 	# echo $__width x $__height
# 
# 	propset width $__width
# 	pset progress.width=$__width
# 	pbar_width=$__width
# 	echo width: $__width
# }
# 	
# function progress.show
# {
# 	local __pbar_fill
# 	local __pbar_width
# 	local __pbar_value
# 	local __pbar_max
# 
# 	put progress.width into __pbar_width	; __pbar__width=$pbar_width
# 	put progress.value into __pbar_value	; __pbar__value=$pbar_value
# 	put progress.max   into __pbar_max		; __pbar__max=$pbar_max

