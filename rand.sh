#!/usr/bin/env bash

function randnum
{
	S="$( dd if=/dev/random bs=1 count=4 | xxd -p )"

	for ((r=, n=0; n<7; n++))
	do
		r+=$(( 0x${S:$n:1} % 10 ))
	done

	echo $r
}

randnum
