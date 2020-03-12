#!/usr/bin/env bash
. include binary || exec date +"Couldn't include required file"

fast_chr() {
	local __octal
	local __char
	printf -v __octal '%03o' $1
	printf -v __char \\$__octal
	REPLY=$__char
}

fast_ord() {
	local __decimal
	printf -v __decimal '%d' "'$1"
	REPLY=$__decimal
}


### 
# @brief output UTF-8 from ordinal value
##
function unichr 
{
	local c=$1	# ordinal of char
	local l=0	# byte ctr
	local o=63	# ceiling
	local p=128	# accum. bits
	local s=''	# output string

	(( c < 0x80 )) && { fast_chr "$c"; echo -n "$REPLY"; return; }

	while (( c > o )); do
		fast_chr $(( t = 0x80 | c & 0x3f ))
		s="$REPLY$s"
		(( c >>= 6, l++, p += o+1, o>>=1 ))
	done


	fast_chr $(( t = p | c ))
	echo -n "$REPLY$s"
}

##
# @brief get ordinal UTF-16 value for UTF-8 character
# (reads character from stdin)
#
# @return ordinal value in REPLY
function uniord
{
	local i l o p __charray
	binary.read
	set -- "${int_array[@]}"

	(( $# < 2 )) && echo "Args: $@"

	for (( l=0, p=0x80, o=p/2-1, REPLY=$1 ;; l++, p+=o+1, o>>=1, REPLY=$1 ))
	do
		__charray+=( $(( l ? REPLY & 0x3f : REPLY )) )
		shift && (( $# )) && (( $1 & 0x80 )) || break 
	done ; # UNPROCESSED=( "$@" )	# We might use this one day

	for (( __charray[0] &= o, REPLY=0, i=0; i<=l; i++ ))
	do
		(( REPLY |= __charray[i] << ( 6* (l-i) ) ))
	done
}

# Uncomment for test:
# unichr $(( 0x2588 )) > /tmp/1
# uniord < /tmp/1
# echo $REPLY

# the below only works if unichr was already defined outside this script (wierd)
# uniord <( unichr $(( 0x2588 )) ) && echo $REPLY
# echo $REPLY
