# rawurlencode: Returns a string in which all non-alphanumeric characters
# except -_.~ have been replaced with a percent (%) sign followed by two hex
# digits.  
# eg:  echo http://url/q?=$( rawurlencode "$args" )
# eg:  rawurlencode "$args"; echo http://url/q?${REPLY}
rawurlencode() {
	local pos=0
	local string="${1}"
	local strlen=${#string}
	local encoded=""
	local c

	for (( pos=0 ; pos<strlen ; pos++ )); do
		c=${string:$pos:1}
		case "$c" in
			[-_.~a-zA-Z0-9] ) o="${c}" ;;
			* )               printf -v o '%%%02X' "'$c"
		esac
		encoded+="${o}"
	done
	echo "${encoded}"    # You can either set a return variable (FASTER) 
	REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
}

rawurlencode_bash3() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"    # You can either set a return variable (FASTER) 
  REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
}
# Returns a string in which the sequences with percent (%) signs followed by
# two hex digits have been replaced with literal characters.
rawurldecode() {

	# This is perhaps a risky gambit, but since all escape characters must be
	# encoded, we can replace %NN with \xNN and pass the lot to printf -b, which
	# will decode hex for us

	printf -v REPLY '%b' "${1//%/\\x}"

	echo "${REPLY}"    # You can either set a return variable (FASTER) 
	REPLY="${decoded}"   #+or echo the result (EASIER)... or both... :p
}
