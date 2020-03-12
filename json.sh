#!/usr/bin/env bash

# http://tldp.org/LDP/abs/html/string-manipulation.html#GETOPTSIMPLE

_command_not_found_handle () 
{ 
	echo "The following command is not valid: \""$1\""";
	echo "With the following argument(s): "
	for args in "$@"; do
		echo \""$args"\"
	done
}

# http://stackoverflow.com/questions/918886/split-string-based-on-delimiter-in-bash
# You can read everything at once without using a while loop: read -r -d '' -a addr <<< "$in" # The -d '' is key here, it tells read not to stop at the first newline (which is the default -d) but to continue until EOF or a NULL byte (which only occur in binary data).
# read ADDR1 ADDR2 <<<$(IFS=";"; echo $IN)
# IP=1.2.3.4; IP=(${IP//./ });

# http://stackoverflow.com/questions/3112687/how-to-iterate-over-associative-array-in-bash
# for i in "${!array[@]}"
# do
#	  echo "key  : $i"
#	  echo "value: ${array[$i]}"
# done

# declare -A fullNames
# fullNames=( ["lhunath"]="Maarten Billemont" ["greycat"]="Greg Wooledge" )
# for user in "${!fullNames[@]}"
# do
# 	echo "User: $user, full name: ${fullNames[$user]}."
# done


# {s:9:"operation";s:3:"pop";s:9:"stackname";s:6:"AddApp";}
# {"operation":"pop","stackname":"ipsFree"}
# Task 1.  Make a 1 dimensional associative array containing only strings.

# chr() - converts decimal value to its ASCII character representation
# ord() - converts ASCII character to its decimal value
# (taken from http://wooledge.org:8000/BashFAQ)
chr() {
  printf \\$(printf '%03o' $1)
}

ord() {
  printf '%d' "'$1"
}

pplslash() {
	local cmd="$1"
	shift
	local -a a=()
	for arg in "$@"; do
		arg="${arg//\"/\\\"}" 	# arg="${arg//\\/\\\\}"
		a+=( "$arg" )
	done
	"$cmd" "${a[@]}"
}

declare -a JSONTABLE # This still makes for a local declaration, a tad inefficient
JSONTABLE[  8]="\\b"
JSONTABLE[  9]="\\t"
JSONTABLE[ 10]="\\n"
JSONTABLE[ 12]="\\f"
JSONTABLE[ 13]="\\r"
JSONTABLE[ 34]="\\\""
JSONTABLE[ 47]="\\/"
JSONTABLE[ 92]="\\\\"
# local i
for i in {0..31} 47 92 127; do
	test -z "${JSONTABLE[$i]}" &&
		printf -v "JSONTABLE[$i]" '\\%04x' $i
done

json_escape() {

#	JSONTABLE[  0]="\\u0000"
#	JSONTABLE[  1]="\\u0001"
#	JSONTABLE[  2]="\\u0002"
#	JSONTABLE[  3]="\\u0003"
#	JSONTABLE[  4]="\\u0004"
#	JSONTABLE[  5]="\\u0005"
#	JSONTABLE[  6]="\\u0006"
#	JSONTABLE[  7]="\\u0007"
#	JSONTABLE[ 11]="\\u000b"
#	JSONTABLE[ 14]="\\u000e"
#	JSONTABLE[ 15]="\\u000f"
#	JSONTABLE[ 16]="\\u0010"
#	JSONTABLE[ 17]="\\u0011"
#	JSONTABLE[ 18]="\\u0012"
#	JSONTABLE[ 19]="\\u0013"
#	JSONTABLE[ 20]="\\u0014"
#	JSONTABLE[ 21]="\\u0015"
#	JSONTABLE[ 22]="\\u0016"
#	JSONTABLE[ 23]="\\u0017"
#	JSONTABLE[ 24]="\\u0018"
#	JSONTABLE[ 25]="\\u0019"
#	JSONTABLE[ 26]="\\u001a"
#	JSONTABLE[ 27]="\\u001b"
#	JSONTABLE[ 28]="\\u001c"
#	JSONTABLE[ 29]="\\u001d"
#	JSONTABLE[ 30]="\\u001e"
#	JSONTABLE[ 31]="\\u001f"
#	JSONTABLE[127]="\\u007f"
#	JSONTABLE[  8]="\\u0008"
#	JSONTABLE[  9]="\\u0009"
#	JSONTABLE[ 10]="\\u000a"
#	JSONTABLE[ 12]="\\u000c"
#	JSONTABLE[ 13]="\\u000d"

	local STRING="${1}"
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

aarray2json() {
	# see http://stackoverflow.com/questions/4069188/how-to-pass-an-associative-array-as-argument-to-a-function-in-bash
	# set -o xtrace
	# eval "declare -A func_assoc_array="${1#*=}
	# declare -p func_assoc_array >&2
	# unset func_assoc_array
	local defn="${1#*=\'}"
	defn="${defn%\'}"
	local -A func_assoc_array=$defn

	# local -A func_assoc_array=${1#*=}
	# eval declare -A func_assoc_array=${1#*=}
	# declare -p func_assoc_array >&2
	# set +o xtrace
	# declare -p func_assoc_array >&2

	OIFS=$IFS
	IFS=
	json=
	for key in "${!func_assoc_array[@]}"
	do
		value="${func_assoc_array[$key]}"

		e_key="$( json_escape "$key" )"
		e_value="$( json_escape "$value" )"

		json_pair="\"${e_key}\":\"${e_value}\""
		json="${json}${json_pair},"
	done

	# remove trailing comma
	json=${json%,}

	# add surrounding braces
	json="{${json}}"
	echo "$json"
	IFS=$OIFS
}

# json2array() {
	# properties {"checkprops.testkey":"checkprops.testval""checkprops.testkey2":"""my.random.key.18156":"""":""}
# }

function aaray2json_ref {
	# this version passes by reference and returns as $JSON
	[ "$#" -ne "1" ] && echo no arguments > /dev/stderr && return 1

	# couldn't find a way to pass it properly, so we're doing the same declare trick, but it's done inside the function.

	def="$( declare -p "$1" )" 

	read _declare _type _definition < <( declare -p "$1" )
	# declare -p _declare _type _definition
	# _type=${_type:1:1}		# A)ssociate  a)rray  -)var  f)function ?
	_type=${_type##-}		# A)ssociate  a)rray  -)var  f)function ?
	[ -n "$_type" ] && _type="-$_type"

	# see http://stackoverflow.com/questions/4069188/how-to-pass-an-associative-array-as-argument-to-a-function-in-bash
	# echo eval "local -A func_assoc_array="${json_command#*=}

	local de="${def#*=\'}"
	de="${de%\'}"
	# eval echo "declare -${_type} func_assoc_array=$de"
	# eval "declare -${_type} func_assoc_array=$de"
	local $_type func_assoc_array=$de
	# declare -p func_assoc_array
	# sleep 1
	# declare -A func_assoc_array='([0]="'\''([operation]=\"push\" [stackname]=\"ba\\\"sh ^B: ^A: ^C: ^? ^H ^I^@:\" )'\''" )'
	# exit
	local key
	local value
	local e_key
	local e_value
	local json_pair
	local json
	local keys
	local ignore_keys=0

	keys=${!func_assoc_array[@]}

	# If it is a non-associative array, or the first key is 0, assume we can ignore keys in JSON output
	if [ "$_type" == "a" -o "${keys[0]}" == "0" ]; then
		ignore_keys=1
	fi

	OIFS=$IFS
	IFS=
	for key in "${!func_assoc_array[@]}"
	do
		value=${func_assoc_array[$key]}

		(( ! ignore_keys )) && e_key="$( json_escape "$key" )"
		e_value="$( json_escape "$value" )"

		if (( ignore_keys )); then
			json="${json}\"${e_value}\","
		else
			json_pair="\"${e_key}\":\"${e_value}\"" json="${json}${json_pair},"
		fi
	done

	# remove trailing comma
	json=${json%,}

	# add surrounding braces
	if (( ignore_keys )); then
		json="[${json}]"
	else
		json="{${json}}"
	fi
	JSON=$json	# JSON is global
	# echo "$json"
	IFS=$OIFS
}

# gearman_stack stackname operation [value] 
# gearman_stack ( insert | push | unshift | pop | slice | splice | shift | get | clear | count ) stackname [ value ]
# eg:  gearman_stack pop MyStack
#      gearman_stack push MyStack "This is a value"
# operations: insert push unshift pop slice splice shift get clear count
gearman_stack() {
	SERVER_ADDR=localhost
	SERVER_PORT=4731

	argc=$#
	declare -A stackargs=( ["operation"]="$1" ["stackname"]="$2" )
	(( argc == 3 )) && stackargs["value"]="$3"
	json_command="$( aarray2json "$( declare -p stackargs )" )"
	echo Stack "${json_command}"

	exec 5<>/dev/tcp/$SERVER_ADDR/$SERVER_PORT
	el=$?
	(( el )) && 
	{
		echo "Could not connect to GearProxy on $SERVER_ADDR:$SERVER_PORT ( errorlevel $el )"
		exit 1
	}

	echo Stack2 "${json_command}" >&5
	while IFS="" read -r REPLY <&5
	do
		LASTREPLY="${REPLY}"
		echo "$REPLY"
	done
	echo "Last line: $REPLY"
	REPLY="${LASTREPLY}"
}

test_crap() {
	# declare an assocociative array
	# declare -A assoc_array=(["key1"]="value1" ["key2"]="value2")
	# show assocociative array definition
	# declare -p assoc_array
	# pass assocociative array in string form to function
	# print_array "$(declare -p assoc_array)"

	IFS=
	# declare -A AA='(["operation"]="push" ["crlf"]="cr$( chr 13 )lf$( chr 10 )." ["stackname"]="ba\"sh ^B: ^A:$( chr 1 ) ^C: ^?:$( chr 127 ) ^H: ^I:$( chr 127 )^@:$( chr 0 )")'
	declare -A AA='([this]="that" ["operation"]="push" ["crlf"]="crlf")'
	declare -p AA

	# AA["stackname"]="bash"

	IFS=
	# AA["operation"]="push"
	for i in "${!AA[@]}"
	do
		echo "key   : $i"
		echo "value : ${AA[$i]}" | xxd
	done
	unset IFS

	time {
		declare -A AA='([this]="that" ["operation"]="push" ["crlf"]="crlf")'
		json=$( aarray2json "$(declare -p AA)" )
		echo encoded json is: $json
		echo; echo
	}

	time (
		declare -A AA='([this]="that" ["operation"]="push" ["crlf"]="crlf")'
		aaray2json_ref AA
		echo; echo
		echo encoded jsonref is $JSON
	)
}

# test_crap
# exit 0
# 
# gearman_stack push bash "Test Value"
# gearman_stack push bash "Another Test Value"
# gearman_stack pop bash
