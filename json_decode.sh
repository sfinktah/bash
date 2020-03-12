#!/usr/bin/env bash
. include mysql array_shift sshlink
# http://tldp.org/LDP/abs/html/string-manipulation.html#GETOPTSIMPLE

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
  printf -v $2 \\$(printf '%03o' $1)
}

ord() {
  printf -v $2 '%d' "'$1"
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

	STRING=$1
	strlen=${#STRING} 
	for (( pos=0 ; pos<strlen ; pos++ )); do
		c=${STRING:$pos:1}
		ord "$c" o
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

function aaray2json_ref {
	# this version passes by reference and returns as $JSON
	[ "$#" -ne "1" ] && echo no arguments > /dev/stderr && return 1

	# couldn't find a way to pass it properly, so we're doing the same declare trick, but it's done inside the function.

	def="$( declare -p AA )"
	read _declare _type _definition < <( echo "$def" )
	# declare -p _declare _type _definition
	_type=${_type:1:1}		# A)ssociate  a)rray  -)var  f)function ?
	# see http://stackoverflow.com/questions/4069188/how-to-pass-an-associative-array-as-argument-to-a-function-in-bash
	# echo eval "local -A func_assoc_array="${json_command#*=}

	local de="${def#*=}"
	eval echo "declare -${_type} func_assoc_array=$de"
	eval "declare -${_type} func_assoc_array=$de"
	declare -p func_assoc_array
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

function key.clear {
	key=
}
function value.clear {
	value=
}

function pair.show {
	# (( indent_depth = ( depth - 1 ) * 4 ))
	# printf -v indent "%${indent_depth}s" ""
	# declare -p KEYS
	implode "." "${KEYS[@]}"
	printf "%s.%s = %s;\n" "$IMPLODED" "$key" "$value"
	echo "key: $key value: $value"
	array[$key]="$value"
	# set -o xtrace
	# eval "$IMPLODED.$key() { echo '$value'; }"
	x="$IMPLODED.$key"
	eval "function $x { echo '$value'; }"
	export -f "$IMPLODED.$key"
	set +o xtrace
	# export -f $IMPODED.$key
}


function buf.clear {
	# printf "Cleared buf: '%s'\n" "$buf"
	# printf "Cleared qbuf: '%s'\n" "$qbuf"
	buf=
	qbuf=
}
test_decode() {



	string='
	{ "1" : { "2" : { "3" : { "4" : "five", "4a" : "six", "4b" : "seven" }}}}
	'

	string='
	{"1":{"start":6,"end":6},"2":{"start":7,"end":8},"3":{"start":9,"end":12},"4":{"start":13,"end":15},"5":{"start":16,"end":18},"6":{"start":19,"end":21},"7":{"start":22,"end":23},"8":{"start":24,"end":25},"9":{"start":26,"end":29},"10":{"start":30,"end":-1}}
	'

	string='{
		 "config": {
			  "preferred-install": "dist"
		 }, 
		 "description": "The Laravel Framework.", 
		 "minimum-stability": "dev", 
		 "name": "laravel/laravel", 
		 "require": {
			  "barryvdh": "dev-master", 
			  "laravel": "4.0.0", 
			  "way": "dev-master"
		 }
	}'


	string='
	{"chapter1":{"start":"chapter6","end":"chapter6"},"chapter2":{"start":"chapter7","end":"chapter8"},"chapter3":{"start":"chapter9","end":"chapter12"},"chapter4":{"start":"chapter13","end":"chapter15"},"chapter5":{"start":"chapter16","end":"chapter18"},"chapter6":{"start":"chapter19","end":"chapter21"},"chapter7":{"start":"chapter22","end":"chapter23"},"chapter8":{"start":"chapter24","end":"chapter25"},"chapter9":{"start":"chapter26","end":"chapter29"},"chapter10":{"start":"chapter30","end":"chapter1"}}
	'
	string='
{"1":{"ip":"184.75.174.10","name":"NewYork","uCount":"607","maxUsers":"7500","status":"OK","id":"1","type":"normal","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"2":{"ip":"184.75.174.11","name":"LosAngeles","uCount":"688","maxUsers":"7500","status":"OK","id":"2","type":"normal","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"15":{"ip":"184.75.174.24","name":"Denver","uCount":"602","maxUsers":"7500","status":"OK","id":"15","type":"normal","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"30":{"ip":"184.75.174.39","name":"Miami","uCount":"638","maxUsers":"7500","status":"OK","id":"30","type":"normal","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"41":{"ip":"184.75.174.50","name":"Dallas","uCount":"552","maxUsers":"7500","status":"OK","id":"41","type":"normal","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"48":{"ip":"184.75.174.57","name":"Baltimore","uCount":"715","maxUsers":"7500","status":"OK","id":"48","type":"normal","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"60":{"ip":"184.75.174.69","name":"California","uCount":"525","maxUsers":"7500","status":"OK","id":"60","type":"normal","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"93":{"ip":"184.75.174.102","name":"Hsinchu","uCount":"617","maxUsers":"7500","status":"OK","id":"93","type":"normal","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"105":{"ip":"184.75.174.114","name":"Shanghai","uCount":"686","maxUsers":"7500","status":"OK","id":"105","type":"normal","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"109":{"ip":"184.75.174.118","name":"Berlin","uCount":"701","maxUsers":"7500","status":"OK","id":"109","type":"normal","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"112":{"ip":"184.75.174.121","name":"Moscow","uCount":"580","maxUsers":"7500","status":"OK","id":"112","type":"normal","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"119":{"ip":"184.75.174.128","name":"Auckland","uCount":"752","maxUsers":"7500","status":"OK","id":"119","type":"normal","langPref":"en","portOrder":"9339:b80"},"125":{"ip":"184.75.174.134","name":"Fresno","uCount":"604","maxUsers":"7500","status":"OK","id":"125","type":"normal","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"154":{"ip":"184.75.174.163","name":"Dalian","uCount":"642","maxUsers":"7500","status":"OK","id":"154","type":"normal","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"155":{"ip":"184.75.174.164","name":"Caracas","uCount":"632","maxUsers":"7500","status":"OK","id":"155","type":"normal","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"4":{"ip":"184.75.174.13","name":"Houston","uCount":"1497","maxUsers":"7500","status":"OK","id":"4","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"5":{"ip":"184.75.174.14","name":"SanAntonio","uCount":"1370","maxUsers":"7500","status":"OK","id":"5","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"6":{"ip":"184.75.174.15","name":"Columbus","uCount":"1334","maxUsers":"7500","status":"OK","id":"6","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"9":{"ip":"184.75.174.18","name":"FortWorth","uCount":"1501","maxUsers":"7500","status":"OK","id":"9","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"10":{"ip":"184.75.174.19","name":"Charlotte","uCount":"1478","maxUsers":"7500","status":"OK","id":"10","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"11":{"ip":"184.75.174.20","name":"ElPaso","uCount":"1516","maxUsers":"7500","status":"OK","id":"11","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"14":{"ip":"184.75.174.23","name":"Boston","uCount":"1462","maxUsers":"7500","status":"OK","id":"14","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"17":{"ip":"184.75.174.26","name":"Nashville","uCount":"1426","maxUsers":"7500","status":"OK","id":"17","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"20":{"ip":"184.75.174.29","name":"Tucson","uCount":"1512","maxUsers":"7500","status":"OK","id":"20","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"21":{"ip":"184.75.174.30","name":"Albuquerque","uCount":"2632","maxUsers":"7500","status":"OK","id":"21","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"24":{"ip":"184.75.174.33","name":"Atlanta","uCount":"2003","maxUsers":"7500","status":"OK","id":"24","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"25":{"ip":"184.75.174.34","name":"Sacramento","uCount":"1321","maxUsers":"7500","status":"OK","id":"25","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"26":{"ip":"184.75.174.35","name":"NewOrleans","uCount":"1479","maxUsers":"7500","status":"OK","id":"26","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"27":{"ip":"184.75.174.36","name":"Cleveland","uCount":"1445","maxUsers":"7500","status":"OK","id":"27","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"29":{"ip":"184.75.174.38","name":"Omaha","uCount":"1412","maxUsers":"7500","status":"OK","id":"29","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"36":{"ip":"184.75.174.45","name":"Honolulu","uCount":"1449","maxUsers":"7500","status":"Preferred","id":"36","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"37":{"ip":"184.75.174.46","name":"Minneapolis","uCount":"1402","maxUsers":"7500","status":"OK","id":"37","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"38":{"ip":"184.75.174.47","name":"ColoradoSprings","uCount":"1434","maxUsers":"7500","status":"OK","id":"38","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"43":{"ip":"184.75.174.52","name":"Indianapolis","uCount":"1372","maxUsers":"7500","status":"OK","id":"43","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"46":{"ip":"184.75.174.55","name":"Austin","uCount":"1549","maxUsers":"7500","status":"OK","id":"46","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"51":{"ip":"184.75.174.60","name":"Milwaukee","uCount":"1327","maxUsers":"7500","status":"OK","id":"51","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"54":{"ip":"184.75.174.63","name":"Oakland","uCount":"1321","maxUsers":"7500","status":"OK","id":"54","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"55":{"ip":"184.75.174.64","name":"Raleigh","uCount":"1407","maxUsers":"7500","status":"OK","id":"55","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"57":{"ip":"184.75.174.66","name":"StLouis","uCount":"1437","maxUsers":"7500","status":"OK","id":"57","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"58":{"ip":"184.75.174.67","name":"Cincinnati","uCount":"1505","maxUsers":"7500","status":"OK","id":"58","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"59":{"ip":"184.75.174.68","name":"Louisville","uCount":"1523","maxUsers":"7500","status":"OK","id":"59","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"96":{"ip":"184.75.174.105","name":"CapeTown","uCount":"1393","maxUsers":"7500","status":"OK","id":"96","type":"normal","langPref":"eg","portOrder":"9339:b80"},"97":{"ip":"184.75.174.106","name":"Tokyo","uCount":"1427","maxUsers":"7500","status":"OK","id":"97","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"98":{"ip":"184.75.174.107","name":"London","uCount":"1544","maxUsers":"7500","status":"OK","id":"98","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"99":{"ip":"184.75.174.108","name":"Seoul","uCount":"1411","maxUsers":"7500","status":"OK","id":"99","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"101":{"ip":"184.75.174.110","name":"Mumbai","uCount":"1303","maxUsers":"7500","status":"OK","id":"101","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"102":{"ip":"184.75.174.111","name":"Jakarta","uCount":"1492","maxUsers":"7500","status":"OK","id":"102","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"104":{"ip":"184.75.174.113","name":"Sydney","uCount":"1533","maxUsers":"7500","status":"OK","id":"104","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"106":{"ip":"184.75.174.115","name":"Manila","uCount":"1452","maxUsers":"7500","status":"OK","id":"106","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"111":{"ip":"184.75.174.120","name":"SaoPaulo","uCount":"1369","maxUsers":"7500","status":"OK","id":"111","type":"normal","langPref":"eg","portOrder":"9339:b80","pollRate":"500"},"118":{"ip":"184.75.174.127","name":"Hyderabad","uCount":"1344","maxUsers":"7500","status":"OK","id":"118","type":"normal","langPref":"eg","portOrder":"9339:b80"},"120":{"ip":"184.75.174.129","name":"Dubai","uCount":"1399","maxUsers":"7500","status":"OK","id":"120","type":"normal","langPref":"eg","portOrder":"9339:b80"},"7":{"ip":"184.75.174.16","name":"Istanbul","uCount":"253","maxUsers":"7500","status":"OK","id":"7","type":"normal","langPref":"tr","portOrder":"9339:b80","pollRate":"500"},"12":{"ip":"184.75.174.21","name":"Ankara","uCount":"898","maxUsers":"7500","status":"OK","id":"12","type":"normal","langPref":"tr","portOrder":"9339:b80","pollRate":"500"},"22":{"ip":"184.75.174.31","name":"Izmir","uCount":"541","maxUsers":"7500","status":"OK","id":"22","type":"normal","langPref":"tr","portOrder":"9339:b80","pollRate":"500"},"31":{"ip":"184.75.174.40","name":"Mesa","uCount":"305","maxUsers":"7500","status":"OK","id":"31","type":"normal","langPref":"tr","portOrder":"9339:b80","pollRate":"500"},"40":{"ip":"184.75.174.49","name":"Bursa","uCount":"304","maxUsers":"7500","status":"OK","id":"40","type":"normal","langPref":"tr","portOrder":"9339:b80","pollRate":"500"},"47":{"ip":"184.75.174.56","name":"Memphis","uCount":"293","maxUsers":"7500","status":"OK","id":"47","type":"normal","langPref":"tr","portOrder":"9339:b80","pollRate":"500"},"94":{"ip":"184.75.174.103","name":"Kaohsiung","uCount":"249","maxUsers":"7500","status":"OK","id":"94","type":"normal","langPref":"tr","portOrder":"9339:b80","pollRate":"500"},"107":{"ip":"184.75.174.116","name":"Antalya","uCount":"665","maxUsers":"7500","status":"OK","id":"107","type":"normal","langPref":"tr","portOrder":"9339:b80","pollRate":"500"},"121":{"ip":"184.75.174.130","name":"Adana","uCount":"702","maxUsers":"7500","status":"OK","id":"121","type":"normal","langPref":"tr","portOrder":"9339:b80","pollRate":"500"},"8":{"ip":"184.75.174.17","name":"Madrid","uCount":"1906","maxUsers":"7500","status":"OK","id":"8","type":"normal","langPref":"es","portOrder":"9339:b80","pollRate":"500"},"13":{"ip":"184.75.174.22","name":"Barcelona","uCount":"1998","maxUsers":"7500","status":"OK","id":"13","type":"normal","langPref":"es","portOrder":"9339:b80","pollRate":"500"},"23":{"ip":"184.75.174.32","name":"Valencia","uCount":"1939","maxUsers":"7500","status":"OK","id":"23","type":"normal","langPref":"es","portOrder":"9339:b80","pollRate":"500"},"100":{"ip":"184.75.174.109","name":"MexicoCity","uCount":"1981","maxUsers":"7500","status":"OK","id":"100","type":"normal","langPref":"es","portOrder":"9339:b80","pollRate":"500"},"19":{"ip":"184.75.174.28","name":"Portland","uCount":"1113","maxUsers":"7500","status":"OK","id":"19","type":"normal","langPref":"id","portOrder":"9339:b80","pollRate":"500"},"28":{"ip":"184.75.174.37","name":"KansasCity","uCount":"1207","maxUsers":"7500","status":"OK","id":"28","type":"normal","langPref":"id","portOrder":"9339:b80","pollRate":"500"},"45":{"ip":"184.75.174.54","name":"SanFrancisco","uCount":"1064","maxUsers":"7500","status":"OK","id":"45","type":"normal","langPref":"id","portOrder":"9339:b80","pollRate":"500"},"95":{"ip":"184.75.174.104","name":"Tahiti","uCount":"1122","maxUsers":"7500","status":"OK","id":"95","type":"normal","langPref":"id","portOrder":"9339:b80"},"113":{"ip":"184.75.174.122","name":"Lima","uCount":"1157","maxUsers":"7500","status":"OK","id":"113","type":"normal","langPref":"id","portOrder":"9339:b80","pollRate":"500"},"141":{"ip":"184.75.174.150","name":"Singapore","uCount":"1194","maxUsers":"7500","status":"OK","id":"141","type":"normal","langPref":"id","portOrder":"9339:b80"},"33":{"ip":"184.75.174.42","name":"Rome","uCount":"360","maxUsers":"7500","status":"OK","id":"33","type":"normal","langPref":"it","portOrder":"9339:b80","pollRate":"500"},"35":{"ip":"184.75.174.44","name":"Naples","uCount":"357","maxUsers":"7500","status":"OK","id":"35","type":"normal","langPref":"it","portOrder":"9339:b80","pollRate":"500"},"114":{"ip":"184.75.174.123","name":"BuenosAires","uCount":"286","maxUsers":"7500","status":"OK","id":"114","type":"normal","langPref":"it","portOrder":"9339:b80","pollRate":"500"},"88":{"ip":"184.75.174.97","name":"Panchiao","uCount":"1035","maxUsers":"7500","status":"OK","id":"88","type":"normal","langPref":"fr","portOrder":"9339:b80","pollRate":"500"},"103":{"ip":"184.75.174.112","name":"Lyon","uCount":"950","maxUsers":"7500","status":"OK","id":"103","type":"normal","langPref":"fr","portOrder":"9339:b80","pollRate":"500"},"110":{"ip":"184.75.174.119","name":"Paris","uCount":"944","maxUsers":"7500","status":"OK","id":"110","type":"normal","langPref":"fr","portOrder":"9339:b80","pollRate":"500"},"116":{"ip":"184.75.174.125","name":"Marseille","uCount":"966","maxUsers":"7500","status":"OK","id":"116","type":"normal","langPref":"fr","portOrder":"9339:b80","pollRate":"500"},"61":{"ip":"184.75.174.70","name":"SitNGo1","uCount":"1990","maxUsers":"7500","status":"OK","id":"61","type":"sitngo","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"124":{"ip":"184.75.174.133","name":"SitNGo5","uCount":"2027","maxUsers":"7500","status":"OK","id":"124","type":"sitngo","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"146":{"ip":"184.75.174.155","name":"SitNGo6","uCount":"1971","maxUsers":"7500","status":"OK","id":"146","type":"sitngo","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"66":{"ip":"184.75.174.75","name":"WeeklyTourney2","uCount":"148","maxUsers":"7500","status":"OK","id":"66","type":"tourney","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"145":{"ip":"184.75.174.154","name":"WeeklyTourney3","uCount":"165","maxUsers":"7500","status":"OK","id":"145","type":"tourney","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"67":{"ip":"184.75.174.76","name":"VIP1","uCount":"18","maxUsers":"7500","status":"OK","id":"67","type":"vip","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"68":{"ip":"184.75.174.77","name":"VIP2","uCount":"16","maxUsers":"7500","status":"OK","id":"68","type":"vip","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"69":{"ip":"184.75.174.78","name":"Shootout1","uCount":"655","maxUsers":"7500","status":"OK","id":"69","type":"shootout1","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"70":{"ip":"184.75.174.79","name":"Shootout2","uCount":"626","maxUsers":"7500","status":"OK","id":"70","type":"shootout1","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"71":{"ip":"184.75.174.80","name":"Shootout3","uCount":"715","maxUsers":"7500","status":"OK","id":"71","type":"shootout1","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"72":{"ip":"184.75.174.81","name":"Shootout4","uCount":"699","maxUsers":"7500","status":"OK","id":"72","type":"shootout1","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"75":{"ip":"184.75.174.84","name":"Shootout7","uCount":"646","maxUsers":"7500","status":"OK","id":"75","type":"shootout1","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"77":{"ip":"184.75.174.86","name":"Shootout9","uCount":"448","maxUsers":"7500","status":"OK","id":"77","type":"shootout3","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"78":{"ip":"184.75.174.87","name":"Shootout10","uCount":"498","maxUsers":"7500","status":"OK","id":"78","type":"shootout3","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"79":{"ip":"184.75.174.88","name":"Shootout11","uCount":"513","maxUsers":"7500","status":"OK","id":"79","type":"shootout3","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"143":{"ip":"184.75.174.152","name":"PowerTourney1","uCount":"68","maxUsers":"7500","status":"OK","id":"143","type":"premium_so","langPref":"en","portOrder":"9339:b80","pollRate":"500"},"165":{"ip":"184.75.174.174","name":"Durham","uCount":"639","maxUsers":"7500","status":"OK","id":"165","type":"jump","langPref":"en","portOrder":"9339:b80"}}
'
	# declare -- string="{\"city\":null,\"gender\":\"f\",\"q2\":\"What was your first\\\\r\\\\npet's name?\",\"zip\":\"99185\",\"password\":\"8nax8wed\",\"dob\":\"June 26, 1982\",\"sq1\":\"Melvin\",\"state\":null,\"year\":\"82\",\"firstname\":\"Elisa\",\"pic\":\"http://profile.ak.fbcdn.net/hprofile-ak-snc4/368869_1634802667_2112204747_n.jpg\",\"lastname\":\"Kane\",\"month\":\"6\",\"username\":\"kaneelisa@yahoo.com\",\"proxy\":\"46.23.74.209:9999\",\"id\":\"kaneelisa@yahoo.com\",\"country\":null,\"q1\":\"What is the first name of\\\\r\\\\nyour favorite uncle?\",\"day\":\"26\",\"sq2\":\"Ralph\",\"altemail\":\"ekane3923@gmail.com\"}"

	# string=$( curl http://autoupdate.geo.opera.com/geolocation/ )
	# string=$1
	local string_len=${#string}
	# echo "string_len: $string_len"

	local -a chars=()
	for (( i=0; i<string_len; i++ )); do
		char="${string:$i:1}"
		chars+=("$char")

		##### TODO 
		# Not sure why these two don't work, but would like to find out.
		# echo eval 'chars+=("'$char'")'
		# array_push chars "${string:$i:1}"
		#####
	done
	# declare -p chars

	local depth=0
	local state=0
	local quoting=0
	local escaping=0
	local isarray=0
	local isobject=0
	local iskey=1
	local isvalue=0
	local acount=0
	local buf=
	
	unset KEYS
	unset array
	declare -A array
	isobject=
	isarray=
	key="json"

	while array_shift char chars
	do
		if (( escaping )) 
		then
			buf+="escape $char"
			(( escaping = !escaping ))
		elif (( quoting )) && [[ $char != '"' ]]
		then
			qbuf+=$char
		else
			case "$char" in
				"{" )
					(( depth++ ))

					push $acount
					push $isobject
					push $isarray
					push "$key"
					push "$( array.export array )"
					unset array
					declare -A array

					array_push KEYS "$key"
					# declare -p KEYS

					# echo "object"
					(( isobject = 1, isarray = 0 ))
					(( iskey = 1, isvalue = 0 ))
					;;
				"[" )
					(( depth++ ))

					push $acount
					push $isobject
					push $isarray
					push "$key"
					array_push KEYS "$key"
					# declare -p KEYS

					# printf "%${depth}s array" ""
					(( isobject = 0, isarray = 1 ))
					(( iskey = 0, isvalue = 1 ))
					key.clear
					value.clear
					;;
				"}" )
					(( depth-- ))
					(( isobject = 0, isarray = 0 ))

					value="$( array.export array )"

					unset array
					declare -A array
					pop array_decl; array.import "$array_decl" array
					pop key
					pop isarray
					pop isobject
					pop acount

					array_pop _ignored KEYS
					pair.show
					# declare -p KEYS

					key.clear
					value.clear
					;;
				"]" )
					(( depth-- ))
					(( isobject = 0, isarray = 0 ))

					pop key
					pop isarray
					pop isobject
					pop acount

					key.clear
					value.clear
					;;
				'"' )
					# (( quoting = escaping ^ quoting ))				#  Will that do what we want?  Lets write it properly
					# (( quoting = escaping ? quoting : !quoting ))	#+	better safe than sorry.

					(( quoting = !quoting ))

					(( !quoting )) &&
					{
						(( indent_depth = ( depth - 1 ) * 4 ))
						printf -v indent "%${indent_depth}s" ""

						(( isvalue )) && value=$qbuf && pair.show # printf "${indent}value: \"%s\"\n" "$qbuf"
						(( iskey )) && key=$qbuf # && printf "${indent}key: \"%s\"\n" "$qbuf" 
						(( isvalue = iskey = 0 ))
					}


					# closing quote

					buf.clear

					;;
				\\ )
					(( escaping == !escaping ))
					;;
				: )
					(( iskey = 0, isvalue = 1 ))
					;;
				, )
					# pair.show
					key.clear
					value.clear

					(( isobject )) && (( iskey = 1, isvalue = 0 ))
					(( isarray )) && (( iskey = 0, isvalue = 1 ))
					;;
				* )
					buf+=$char

					
			esac
		fi
				

	done

	declare -p array
	array.import "${array[json]}" atmp
	


	return

	export array
	eval "function json { echo '$( array.export atmp )'; }"
	export -f json

}

WALK=json
POS=$array

array.extract()
{
   local arraydef; getarg arraydef && shift
   local varname; getarg varname && shift

   declare -Ag $varname="$arraydef"
}

function walk_ {
	unset atmp
	unset KEYS
	local step=$1
	array.import "$( $WALK )" atmp
	declare -p atmp
	array.keys atmp
	array.in_array $step KEYS && {
		echo stepped into $step
		WALK+=".$step"
	} || {
		echo step $step invalid, choose one of: "${KEYS[@]}"
	}
}

WALK_ORIGIN=atmp
function walk {
	unset KEYS
	unset a

	local step=$1
	array.keys $WALK_ORIGIN
	array.in_array $step KEYS && {
		echo walking to $step
		array.import $WALK_ORIGIN a
		unset atmp
		array.import "${a[$step]}" atmp
		declare -p atmp
	} || {
		echo step $step invalid, choose one of: "${KEYS[@]}"
	}
}

# string=$( curl -s http://bits.wikimedia.org/geoiplookup )
test_decode "$1"
### mysql.server /dev/tcp/localhost/3307
### mysql.setvars atmp
### echo mysql.update "INSERT IGNORE INTO geoip SET ${SETVARS}"
### mysql.update "INSERT IGNORE INTO geoip SET ${SETVARS}"

# walk 1
# json.1.2
# declare -p KEYS

# test_crap
# exit 0
# 
# gearman_stack push bash "Test Value"
# gearman_stack push bash "Another Test Value"
# gearman_stack pop bash
