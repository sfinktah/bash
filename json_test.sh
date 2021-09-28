#!/usr/bin/env bash

# http://tldp.org/LDP/abs/html/string-manipulation.html#GETOPTSIMPLE

command_not_found_handle () 
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

json_escape() {
	declare -a ESCTABLE
	ESCTABLE[  0]="\\u0000"
	ESCTABLE[  1]="\\u0001"
	ESCTABLE[  2]="\\u0002"
	ESCTABLE[  3]="\\u0003"
	ESCTABLE[  4]="\\u0004"
	ESCTABLE[  5]="\\u0005"
	ESCTABLE[  6]="\\u0006"
	ESCTABLE[  7]="\\u0007"
	ESCTABLE[  8]="\\b"
	ESCTABLE[  9]="\\t"
	ESCTABLE[ 10]="\\n"
	ESCTABLE[ 11]="\\u000b"
	ESCTABLE[ 12]="\\f"
	ESCTABLE[ 13]="\\r"
	ESCTABLE[ 14]="\\u000e"
	ESCTABLE[ 15]="\\u000f"
	ESCTABLE[ 16]="\\u0010"
	ESCTABLE[ 17]="\\u0011"
	ESCTABLE[ 18]="\\u0012"
	ESCTABLE[ 19]="\\u0013"
	ESCTABLE[ 20]="\\u0014"
	ESCTABLE[ 21]="\\u0015"
	ESCTABLE[ 22]="\\u0016"
	ESCTABLE[ 23]="\\u0017"
	ESCTABLE[ 24]="\\u0018"
	ESCTABLE[ 25]="\\u0019"
	ESCTABLE[ 26]="\\u001a"
	ESCTABLE[ 27]="\\u001b"
	ESCTABLE[ 28]="\\u001c"
	ESCTABLE[ 29]="\\u001d"
	ESCTABLE[ 30]="\\u001e"
	ESCTABLE[ 31]="\\u001f"
	ESCTABLE[ 34]="\\\""
	ESCTABLE[ 47]="\\/"
	ESCTABLE[ 92]="\\\\"
	ESCTABLE[127]="\\u007f"
#	ESCTABLE[  8]="\\u0008"
#	ESCTABLE[  9]="\\u0009"
#	ESCTABLE[ 10]="\\u000a"
#	ESCTABLE[ 12]="\\u000c"
#	ESCTABLE[ 13]="\\u000d"

	STRING="${1}"
	strlen=${#STRING} 
	for (( pos=0 ; pos<strlen ; pos++ )); do
		c=${STRING:$pos:1}
		o=$( ord $c )

		if [ ! -z "${ESCTABLE[$o]}" ]; then
			echo -n "${ESCTABLE[$o]}"
		else
			echo -n "$c"
		fi
	done
}

aarray2json() {
	# see http://stackoverflow.com/questions/4069188/how-to-pass-an-associative-array-as-argument-to-a-function-in-bash
	eval "declare -A func_assoc_array="${1#*=}

	OIFS=$IFS
	IFS=
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
	declare -A AA='(["operation"]="push" ["crlf"]="cr
lf")'
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

	##  json=$( aarray2json "$(declare -p AA)" )
	# echo encoded json is: $json

	aaray2json_ref AA
	echo encoded json is $JSON
}

# accept the name of an array as $1 and returns a JSON encoded string as "$JSON"
function aaray2json_ref {
	[ "$#" -ne "1" ] && echo no arguments > /dev/stderr && return 1

	# couldn't find a way to pass it properly, so we're doing the same declare trick, but it's done inside the function.

	read _declare _type _definition < <( declare -p "$1" )
	local _type=${_type:1:1}		# A)ssociate  a)rray  -)var  f)function ?
											# echo eval "local -A func_assoc_array="${json_command#*=}

	local _def="${_definition#*=}"
	# eval "declare -${_type} func_assoc_array=$_def"
	echo declare -$_type func_assoc_array=$_def
	declare -A A
	export A=$_def
	declare -p A
	
	# declare -p func_assoc_array
	sleep 1
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
declare -A A='([a]="1" [b]="2" [c]="3" )'
aaray2json_ref A
declare -p JSON

# test_crap
# exit 0
# 
# gearman_stack push bash "Test Value"
# gearman_stack push bash "Another Test Value"
# gearman_stack pop bash
