#!/bin/bash

	case "$1" in
		'' ) 
			src="${BASH_SOURCE[0]}"
			;;
		*[!0-9]* )
			src="$1"
			;;
		* )
			src="${BASH_SOURCE[$1]}"
	esac

	test -L "$src" && src="$( readlink "$src" )"

	case "${src:0:1}" in
		. )
			src="${src#.#$( pwd -P )}"
			;;
		/ )
			;;
		* )
			src="$( pwd -P )/$src"
	esac
	echo $src
	
# BASEDIR[$$]="$( dirname $( realpath "${BASH_SOURCE[0]}" ) )"
# . ${BASEDIR[$$]}/included.inc.sh
# realpath
# dirname $(realpath)

# readlink ${BASH_SOURCE[0]}
# test -L "${BASH_SOURCE[0]}
