#!/usr/bin/env bash
BASEDIR=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)
. ${BASEDIR}/includer.inc.sh upvars classes

pbar_max=$( wc -l < stoppedCurrent.txt )
pbar_value=0
pbar_min=0
pbar_width=80

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
	local __class=${1%%.*}
	local __varname=${1#*.}
	local __full_varname="__${__class}__${__varname}"
	declare -g $__full_varname
}

# usage: pset class.property=value
# eg:    pset $this.p=$VALUE
function pset
{
	local __rhs=${1%%=*}
	local __lhs=${1##*=}
	local __class=${__lhs%%.*}
	local __varname=${__lhs#*.}
	local __full_varname="__${__class}__${__varname}"

	declare -p | grep __

	declare -g $__full_varname="$__rhs"
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

var progress.screen_width
var progress.max
var progress.min
var progress.width
var progress.value

function progress.__construct
{
	scope

	local __height
	local __width

	propset min 0
	pset progress.min=0
	read __height __width < <( stty size )
	(( __width -= 15 ))
	# echo $__width x $__height

	propset width $__width
	pset progress.width=$__width
	pbar_width=$__width
	echo width: $__width
}
	
function progress.show
{
	local __pbar_fill
	local __pbar_width
	local __pbar_value
	local __pbar_max

	put progress.width into __pbar_width	; __pbar__width=$pbar_width
	put progress.value into __pbar_value	; __pbar__value=$pbar_value
	put progress.max   into __pbar_max		; __pbar__max=$pbar_max

	(( __pbar_fill = ( __pbar_width * __pbar__value ) / __pbar__max - 1 ))

	local __bar
	local __fullbar

	printf -v ___bar "%0${__pbar_fill}d" 0 
	__bar="${__bar//0/=}>"
   printf -v __fullbar "%-${__pbar_width}s" "$__bar"

	local __percent=$(( 100 * __pbar__value / __pbar__max ))
	printf "%3d%% [%s]\r" $__percent "$__fullbar"
}

progress.__construct

echo

count=0
for account in $( cat stoppedCurrent.txt )
do
   (( pbar_value++ ))
   progress.show
	if (( count++ > 10 ))
	then
		count=0
		sleep 1
	fi
   # php PlayerInfoClass.php "$account" > /dev/null
done
echo


progress.tostring() {
	scope
	echo "$this" "string is" "$1"
}

progress.xoutput() {
	scope
	$this.tostring magic
}

