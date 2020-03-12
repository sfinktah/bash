#!/usr/bin/env bash
__DEBUG=1
source include arrays filesize
function decho
{
	(( __DEBUG )) && echo "$@"
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

cat files.iphoto.txt |
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



	__target="$dn/$noext.$ext"

	filetype="$( file "$fn" )"
	filetype="${filetype#*: }"

	case "$filetype" in

		("Composite Document File V2"*)
			ft=thm
			decho Thumbs.db: "$fn"
			;;
		"Apple binary property list" )
			ft=plist
			;;
		*JPEG* )
			ft=jpg
			explode "/" "$fn"
			# declare -p EXPLODED

			# JPEG (514319):  ./iPhoto Library Recovered Photos/AEA5346FACD24CC88CA5B9AD49784D60
			# JPEG (1565908): ./iPhoto Library/Modified/2003/pandita/IMG_0802.JPG
			# JPEG (52604):   ./iPhoto Library/Data.noindex/2000/Bitch/DSCF0574.jpg

			# while array_shift EXPLODED into __subdir
			# do
			#		echo "shifted: $__subdir"
			# done
			# continue

			__basepath=
			array_shift EXPLODED

			case "${EXPLODED[0]}" in
				"iPhoto Library Recovered Photos" )
					array_shift EXPLODED
					__basepath="Recovered"
					;;
				"iPhoto Library" )
					array_shift EXPLODED
					;;
				* )
					echo "Unknown first subdir: ${EXPLODED[0]}"
					echo
					continue
					;;
			esac

			# array_shift EXPLODED into __subdir
			# declare -p EXPLODED
			while true
			do
				case "${EXPLODED[0]}" in
					"Modified" )
						array_shift EXPLODED into __subdir
						;;
					"Data.noindex" )
						array_shift EXPLODED into __subdir
						;;
					"Originals" )
						array_shift EXPLODED
						;;
					20?? )
						array_shift EXPLODED
						;;

					* )
						echo "Unknown second subdir: '${EXPLODED[0]}'"
						declare -p EXPLODED
						echo
						if (( ${#EXPLODED[@]} == 1 )) 
						then
							__fp="${__basepath}/${EXPLODED[*]}"
						elif (( ${#EXPLODED[@]} == 2 )) 
						then
							__fp="${EXPLODED[0]}/${EXPLODED[1]}"
						else
							echo "Path too long: ${EXPLODED[@]}"
							break
						fi

						process "$fn" "$__fp"
						break
						;;
				esac
			done
			continue


			false && 
			if [ -e "$__target" ] 
			then
				diff "$fn" "$__target" || 
				{
					echo "Diff error: \"$fn\" and \"$__target\""
					continue
				}
			fi

			decho JPEG "($size)": "$fn"
			;;
		* )
			echo "UNKNOWN ($filetype): $__target"
			ft=
	esac
done

# check for short arg within long arg

