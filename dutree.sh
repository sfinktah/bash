#!/usr/bin/env bash
. include array

hostname=$( cat /etc/hostname )
(( min = 25 * 1000 ))
base=${1:-/}

function device {
	stat --printf="%d" "$1"
}

baseDevice=$( device "$base" )

function isSameDevice {
	path=$1
	dev=$( device "$path" )
	[[ $baseDevice = $dev ]] && return 0
	return 1
}


function scan {
	# echo SCANNING: "'$1'"
	sudo du -xsk "$1"/* | while read -r size path; do
		echo $size "$path" >&2
		(( size > min )) && isSameDevice "$path" && {
			test -d "$path" && {
				echo "{size:$size,path:\"/$hostname${path//\"/\\\"}\",type:\"path\"},"
				scan "$path"
				true
			} || {
				echo "{size:$size,path:\"/$hostname${path//\"/\\\"}\",type:\"file\"},"
			}
		}
	done
}

echo -n "stink=["
# for fn in /
# do
#	scan "$fn"
# done
scan ""
echo "]"
