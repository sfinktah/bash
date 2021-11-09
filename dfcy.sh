#!/usr/bin/env bash
. include explode realpath warning

function dospath
{ 
    bn=$(basename "$1");
    dn=$(dirname "$1");
    \cd "$1" && cmd /c cd;
    \cd "$dn";
    ddn=$( cmd /c cd );
    echo "${ddn%}\\$bn"
}

function dospathfwd
{
    bn=$(basename "$1");
    dn=$(dirname "$1");
    \cd "$1" && cmd /c cd;
    \cd "$dn";
    ddn=$( cmd /c cd );
	ddn=${ddn%$'\r'}
	ddn=${ddn//\\/\/}
    echo "${ddn%$'\r'}\\$bn"
}

function read.line
{
	read -r 
}

# Filesystem                             Size  Used Avail Use% Mounted on
# C:/Users/sfink/Downloads/cyg-packages  466G  465G  891M 100% /
# E:                                     391G  385G  6.0G  99% /cygdrive/e
# H:                                     3.7T  3.6T   57G  99% /cygdrive/h
# R:                                     128M   42M   87M  33% /cygdrive/r
# 
# C:/Users/sfink/Downloads/cyg-packages/bin on /usr/bin type ntfs (binary,auto)
# C:/Users/sfink/Downloads/cyg-packages/lib on /usr/lib type ntfs (binary,auto)
# C:/Users/sfink/Downloads/cyg-packages on / type ntfs (binary,auto)
# C:/Users/sfink/AppData/Local/Temp on /tmp type ntfs (binary,posix=0,usertemp)
# C: on /cygdrive/c type ntfs (binary,posix=0,user,noumount,auto)
# E: on /cygdrive/e type ntfs (binary,posix=0,user,noumount,auto)
# H: on /cygdrive/h type ntfs (binary,posix=0,user,noumount,auto)
# R: on /cygdrive/r type ntfs (binary,posix=0,user,noumount,auto)

function dfc 
{
	local match=
	local matchdev=
	local here=$( realpath . 2>/dev/null )

	regex='^(.*) on (.*) type (.*) \((.*)\)'
	while read.line
	do
		[[ $REPLY =~ $regex ]] || { warning "Couldn't match regex on line: $REPLY"; continue; }

		local disk=${BASH_REMATCH[1]}
		local mount=${BASH_REMATCH[2]}
		local type=${BASH_REMATCH[3]}	# We'll not be using this
		local options=${BASH_REMATCH[4]}	# We'll not be using this

		debug "disk:$disk mount:$mount"

		[[ $here == $mount* ]] && {
			debug "len(mount):${#mount}"
			(( ${#mount} > ${#match} )) && match=$mount matchdev=$disk
		}
	done < <( mount )
	test -n "$match" && df -h "$match"
}

dfc
