chr() {
  printf \\$(printf '%03o' $1)
}

ord() {
  printf '%d' "'$1"
}

unset JSONTABLE
declare -a JSONTABLE 
JSONTABLE[  8]="\\b"
JSONTABLE[  9]="\\t"
JSONTABLE[ 10]="\\n"
JSONTABLE[ 12]="\\f"
JSONTABLE[ 13]="\\r"
JSONTABLE[ 34]="\\\""
JSONTABLE[ 47]="\\/"
JSONTABLE[ 92]="\\\\"
for i in {0..31} 47 92 127; do
	test -z "${JSONTABLE[$i]}" &&
	printf -v "JSONTABLE[$i]" '\\%04x' $i
done

json_escape() {
	local STRING=$1
	local RESULT=""
	local strlen=${#STRING} 
   local pos c o
	for (( pos=0 ; pos<strlen ; pos++ )); do
		c=${STRING:$pos:1}
		o=$( ord "$c" )
		# printf "%04x %d '%s'\n" "$o" "'$c" "$( echo -n "$c" | xxd)"

		if [ ! -z "${JSONTABLE[$o]}" ]; then
			RESULT+="${JSONTABLE[$o]}"
			# echo -n "${JSONTABLE[$o]}"
		else
			RESULT+="$c"
			# echo -n "$c"
		fi
	done
	echo "$RESULT"
}
