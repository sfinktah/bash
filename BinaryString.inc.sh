#!/usr/bin/env bash
BASEDIR=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)
. ${BASEDIR}/includer.inc.sh upvars classes


## Definition of class BinaryString

class BinaryString

function BinaryString.__construct
{
	scope
	var $this.pos=0
	local buf=""
	local array=""

	if [[ $1 == stdin ]]
	then
		while read; do
			array+=$REPLY
		done  < <( xxd -p )
	fi
	var $this.buf="$array"
}

function BinaryString.tostring
{
	scope
	local buf
	put $this.buf into buf
 	echo -n "$buf" | xxd -p -r
}

function BinaryString.NextByte
{
	scope
	local buf
	local pos
	put $this.buf into buf
	put $this.pos into pos

	local "$1" && upvar $1 "$(( 0x${buf[@]:$(( ( pos ) * 2)):2} ))"
	pset $this.pos=$(( pos + 1 ))
}

function BinaryString.NextWord
{
	scope
	local buf
	local pos
	put $this.buf into buf
	put $this.pos into pos

	local val="$(( 0x${buf[@]:$(( ( pos ) * 2)):4} ))"
	# echo "val: '$val'"
	# local "$1" && upvar $1 "$(( 0x${buf[@]:$(( ( pos ) * 2)):4} ))"
	local "$1" && upvar $1 "$val"
	pset $this.pos=$(( pos + 2 ))
}

function BinaryString.test
{
	## Instantiate "buf" as a BinaryString, and call constructor with argument "stdin"
	## (and pipe in some input)
	new BinaryString buf stdin < <( echo -e 'ABCDEF\n\x1b[1mHello\n\x1b[0mHow are you\n' )

	## Check everything has worked
	buf.tostring

	## Check NextByte
	for i in {1..20}; do 
		buf.NextWord b
		printf "%04x " $b
	done
}

endclass

# BinaryString.test


