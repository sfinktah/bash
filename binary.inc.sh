
##
# @brief read descriptor in binary safe fashion
#
# @param filedescriptor (default: stdin)
# @param timeout (not implemented)
#
# @return globals: hex_array, int_array
function binary.read #(filedescriptor, timeout)
{
	local REPLY array x
	local length=1
	local FD=${1:-0}
	local timeout=${2:-0}	# Breaks /read/

	read -r -u $FD -t 0 -n 0 || { echo no data >&2 ; return 1; }
	while read; do
		array+=$REPLY
	done < <( dd bs=2048 count=$length <&$FD 2>/dev/null | xxd -p )

	# TODO: perform /sed/ function via internal function
	hex_array=( $( echo -n "$array" | sed 's/../0x& /g' ) )
	int_array=()
	for x in "${hex_array[@]}"; do
	   int_array+=( $(( $x )) )
	done
}
