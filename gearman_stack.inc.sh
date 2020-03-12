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
