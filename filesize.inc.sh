#!/usr/bin/env bash

function filesize_1
{
	local ln=$( ls -Lon "$1" )
	# -rwxr-xr-x  1 501  346 Mar 20 22:51 filesize.inc.sh
	# ln=${ln## }		# Unnecessary as there are no leading spaces with -L option
	ln=${ln#* }			# Remove permissions
	ln=${ln## }			# Remove leading spaces

	ln=${ln#* }			# Remove block count
	ln=${ln## }			# Remove leading spaces

	ln=${ln#* }			# Remove numeric userid
	ln=${ln## }			# Remove leading spaces
							# Filesize is start of line
	ln=${ln%% *}		# Remove everything else

	echo "$ln"
}

function filesize
{
	local ln=( $( ls -Lon "$1" ) )
	local "$3" && upvar $3 "${ln[3]}"
	# echo ${ln[3]}
}

# filesize_1 "$0"
# filesize_2 "$0"
