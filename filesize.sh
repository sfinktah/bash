#!/usr/bin/env bash

function filesize
{
	__ln=( $( ls -Lon "$1" ) )
	__size=${__ln[3]}
	REPLY=$__size
	echo "$REPLY"
}
