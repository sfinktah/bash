#!/usr/bin/env bash
__DEBUG=1
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

find . -type f |
while read -r fn
do
	# decho $fn
	dirname "$fn" into dn
	basename "$fn" into bn
	extension "$bn" into ext
	noextension "$bn" into noext
	# decho $dn/$bn "($ext)"

	if [[ $dirname =~ ".*AppleDouble.*" ]]
	then
		continue
	fi

	# >f+++++++++ kodak/tmp/101B05924B20465E89910DC6ABD62B4D(1)
	# declare -ar BASH_REMATCH='([0]="1CD89973FBA542C8A6D5F208EFDF44A1.jpg" [1]="1CD89973FBA542C8A6D5F208EFDF44A1" [2]=".jpg")'

	# Check for MD5 (unnamed) files
	if [[ "$bn" =~ "([A-F0-9]{32})(.*)" ]]
	then
		__target="$dn/${BASH_REMATCH[1]}.jpg"
		[[ $fn == $__target ]] && continue
		# declare -p BASH_REMATCH
		filetype="$( file "$fn" )"
		# ./Xmas 2005/FEB252E4781948F18479E7567CB803E5.jpg: JPEG image data, EXIF standard
		filetype="${filetype##*: }"
		case "$filetype" in
			*JPEG* )
				ft=jpg
				if [ -e "$__target" ] 
				then
					diff "$fn" "$__target" || 
					{
						echo "Diff error: \"$fn\" and \"$__target\""
						continue
					}
				fi

				decho mv -f "$fn" "$dn/${BASH_REMATCH[1]}.jpg"
				mv -f "$fn" "$dn/${BASH_REMATCH[1]}.jpg"
				;;
			*CDF* )
				ft=db
				decho mv -f "$fn" "$dn/Thumbs.db"
				mv -f "$fn" "$dn/Thumbs.db"
				;;
			* )
				ft=
		esac
	elif [[ "$bn" =~ "(.*)(\([0-9]\))(.*)" ]]
	then

		# declare -p BASH_REMATCH
		# declare -ar BASH_REMATCH='([0]="IMG_1869(1).JPG" [1]="IMG_1869" [2]="(1)" [3]=".JPG")'
		# declare -ar BASH_REMATCH='([0]="MVI_2119(1).THM" [1]="MVI_2119" [2]="(1)" [3]=".THM")'

		__target="$dn/${BASH_REMATCH[1]}${BASH_REMATCH[3]}"
		if [ -e "$__target" ] 
		then
			diff "$fn" "$__target" || 
			{
				echo "Diff error: \"$fn\" and \"$__target\""
				continue
			}
		fi
		decho mv -f "$fn" "$__target"
 		mv -f "$fn" "$__target"
	fi
	if [[ $ext == "zip" ]] 
	then
		pushd .
		decho cd "$dn" 
		cd "$dn" || exit 1

		decho mkdir -p "$noext"
		mkdir -p "$noext"

		decho cd "$noext" 
		cd "$noext" || exit 1

		decho unzip -n "../$bn"
		unzip -n "../$bn"
		popd
	fi
	shopt -s nocasematch
	if [[ $ext == "thm" ]]
	then
		decho mv -f "$fn" "$fn.jpg"
		mv -f "$fn" "$fn.jpg"
	fi
	shopt -u nocasematch
done

# check for short arg within long arg

