#!/usr/bin/env bash
. include explode realpath warning


function read.line
{
	read -r 
}

function dfc 
{
	local match=
	local matchdev=
	local here=$( realpath . 2>/dev/null )

	regex='^(.*) on (.*) \((.*)\)'
	while read.line
	do
		[[ $REPLY =~ $regex ]] || { warning "Couldn't match regex on line: $REPLY"; continue; }

		local disk=${BASH_REMATCH[1]}
		local mount=${BASH_REMATCH[2]}
		local options=${BASH_REMATCH[3]}	# We'll not be using this

		[[ $here == $mount* ]] && {
			(( ${#mount} > ${#match} )) && match=$mount matchdev=$disk
		}
	done < <( mount )
	test -n "$match" && df -h "$match"
}

dfc
