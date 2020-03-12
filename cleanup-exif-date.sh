#!/usr/bin/env bash
__DEBUG=1
source include arrays filesize
function decho
{
	(( __DEBUG )) && echo "$@"
}

count=0
function get_exif_ctime
{
# 0x9003|2003:11:23 21:54:20
	exif -m --tag="Date and Time (Original)" "$1" 2>/dev/null
	return
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

# array_shift <array_var_name> into <var_name>
function array_shift
{

	(( $# > 1 )) && if [[ $2 != "into" ]]
	then
		echo "Invalid arguments passed to $FUNCNAME: $@" >&2
		return 1
	fi

	local __array_var_name=$1
	local __var_name=$3

	local __first=
	local __rest=

	e="$( declare -p "$__array_var_name" )"; 
	e=${e#*=}
	e=${e#\'}
	e=${e%\'}
	eval "declare E=$e"
	(( ${#E[@]} < 1 )) && return 1
	set -- "${E[@]}"
	# echo "Positional parameters are 1:$1 2:$2 3:$3 4:$4 etc..."
	test -n "$__var_name" && local "$__var_name" && upvar $__var_name "$1"
	shift
	A=( "$@" )
	eval $__array_var_name='("${A[@]}")'
	# local "$__array_var_name" && upvar $__array_var_name "$@"
	# upvar didn't work so well when the array got down to a single member (tried to set it to a flat variable)

	#	
	#   # alias get_array_by_ref='e="$( declare -p ${1} )"; eval "declare -A E=${e#*=}"'
	#   # KEYS=( "${!E[@]}" )
}

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



function basename
{
	local __rv="${1##*/}"
	local "$3" && upvar $3 "$__rv"
}

function dirname
{
	local __rv="${1%/*}"
	local "$3" && upvar $3 "$__rv"
}

function extension
{
	local __rv="${1##*.}"
	local "$3" && upvar $3 "$__rv"
}

function noextension
{
	local __rv="${1%.*}"
	local "$3" && upvar $3 "$__rv"
}

function is_jpeg_ext
{
	local __rv=1
	shopt -s nocasematch
	[[ $1 == jpg ]] && __rv=0
	shopt -u nocasematch
	return $__rv
}

function process
{
	local __sfn=$1
	local __tfn="Cleaned/$2"
	local __tdir=
	dirname "$__tfn" into __tdir
	[ ! -d "$__tdir" ] && mkdir -p "$__tdir"

	local __ssize=
	local __tsize=0
	filesize "$__sfn" into __ssize
	[ -e "$__tfn" ] && filesize "$__tfn" into __tsize
	echo "ssize: $__ssize tsize: $__tsize"
	(( __ssize > __tsize )) && cp "$__sfn" "$__tfn"
}

find . -iname '*.jpg' |
while read -r fn
do
	# decho $fn
	dirname "$fn" into dn
	basename "$fn" into bn
	extension "$bn" into ext
	noextension "$bn" into noext
	# decho $dn/$bn "($ext)"

	[[ $dirname =~ .*AppleDouble.* ]] && continue
	[[ $fn =~ DS_Store ]] && continue



	# [[ $fn == $__target ]] && continue
	# declare -p BASH_REMATCH
	# ./Xmas 2005/FEB252E4781948F18479E7567CB803E5.jpg: JPEG image data, EXIF standard

	test -e "$fn" || continue
	test -s "$fn" || 
	{
		decho "Empty: $fn"; 
		continue 
	}


	date="$( get_exif_ctime "$fn" )" || {
		(( count++ ))
		echo ln -f "$fn" "nodate/$count.jpg"
		ln -f "$fn" "nodate/$count.jpg"
		continue
	}
	
	# 2003:11:23 21:54:20
	date="${date/ /-}"
	date="${date//:/.}"
	__target="bydate/$date.$bn"

	if [ ! -e "$__target" ] 
	then
		echo ln "$fn" "$__target"
		ln "$fn" "$__target"
	fi
done

# check for short arg within long arg

