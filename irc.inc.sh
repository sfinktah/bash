strip_colon() {
	if [ "${1:0:1}" == ":" ]; then
		echo "${1:1}"
	else
		echo "$1"
	fi
}

# <prefix>   ::= <servername> | <nick> [ '!' <user> ] [ '@' <host> ]
split_prefix() {
	WHICH="$1"								# NICK | USER | HOST | USERHOST
	FROM_FULL=$( strip_colon "$2"	)	# <nick> [ '!' <user> ] [ '@' <host> ]

	IFS='!@' FROM_BITS=( $FROM_FULL )
	local NICK="${FROM_BITS[0]}"
	local USER="${FROM_BITS[1]}"
	local ADDR="${FROM_BITS[2]}"
	local USERHOST="${USER}@${HOST}"

	echo "${!WHICH}" 
}
