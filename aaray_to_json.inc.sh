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
