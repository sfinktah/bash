#!/usr/bin/env bash
. include fds
GEARMAN_TIMEOUT="-t 10"


COMMANDS[1]="CAN_DO REQ"
COMMANDS[2]="CANT_DO REQ"
COMMANDS[3]="RESET_ABILITIES REQ"
COMMANDS[4]="PRE_SLEEP REQ"
COMMANDS[6]="NOOP RES"
COMMANDS[7]="SUBMIT_JOB REQ"
COMMANDS[8]="JOB_CREATED RES"
COMMANDS[9]="GRAB_JOB REQ"
COMMANDS[10]="NO_JOB RES"
COMMANDS[11]="JOB_ASSIGN RES"
COMMANDS[12]="WORK_STATUS REQ RES"
COMMANDS[13]="WORK_COMPLETE REQ RES"
COMMANDS[14]="WORK_FAIL REQ RES"
COMMANDS[15]="GET_STATUS REQ"
COMMANDS[16]="ECHO_REQ REQ"
COMMANDS[17]="ECHO_RES RES"
COMMANDS[18]="SUBMIT_JOB_BG REQ"
COMMANDS[19]="ERROR RES"
COMMANDS[20]="STATUS_RES RES"
COMMANDS[21]="SUBMIT_JOB_HIGH REQ"
COMMANDS[22]="SET_CLIENT_ID REQ"
COMMANDS[23]="CAN_DO_TIMEOUT REQ"
COMMANDS[24]="ALL_YOURS REQ"
COMMANDS[25]="WORK_EXCEPTION REQ RES"
COMMANDS[26]="OPTION_REQ REQ"
COMMANDS[27]="OPTION_RES RES"
COMMANDS[28]="WORK_DATA REQ RES"
COMMANDS[29]="WORK_WARNING REQ RES"
COMMANDS[30]="GRAB_JOB_UNIQ REQ"
COMMANDS[31]="JOB_ASSIGN_UNIQ RES"
COMMANDS[32]="SUBMIT_JOB_HIGH_BG REQ"
COMMANDS[33]="SUBMIT_JOB_LOW REQ"
COMMANDS[34]="SUBMIT_JOB_LOW_BG REQ"
COMMANDS[35]="SUBMIT_JOB_SCHED REQ"
COMMANDS[36]="SUBMIT_JOB_EPOCH REQ"

COMMAND_TEXT=0 COMMAND_CAN_DO=1 COMMAND_CANT_DO=2 COMMAND_RESET_ABILITIES=3
COMMAND_PRE_SLEEP=4 COMMAND_UNUSED=5 COMMAND_NOOP=6 COMMAND_SUBMIT_JOB=7
COMMAND_JOB_CREATED=8 COMMAND_GRAB_JOB=9 COMMAND_NO_JOB=10
COMMAND_JOB_ASSIGN=11 COMMAND_WORK_STATUS=12 COMMAND_WORK_COMPLETE=13
COMMAND_WORK_FAIL=14 COMMAND_GET_STATUS=15 COMMAND_ECHO_REQ=16
COMMAND_ECHO_RES=17 COMMAND_SUBMIT_JOB_BG=18 COMMAND_ERROR=19
COMMAND_STATUS_RES=20 COMMAND_SUBMIT_JOB_HIGH=21 COMMAND_SET_CLIENT_ID=22
COMMAND_CAN_DO_TIMEOUT=23 COMMAND_ALL_YOURS=24 COMMAND_WORK_EXCEPTION=25
COMMAND_OPTION_REQ=26 COMMAND_OPTION_RES=27 COMMAND_WORK_DATA=28
COMMAND_WORK_WARNING=29 COMMAND_GRAB_JOB_UNIQ=30 COMMAND_JOB_ASSIGN_UNIQ=31
COMMAND_SUBMIT_JOB_HIGH_BG=32 COMMAND_SUBMIT_JOB_LOW=33
COMMAND_SUBMIT_JOB_LOW_BG=34 COMMAND_SUBMIT_JOB_SCHED=35
COMMAND_SUBMIT_JOB_EPOCH=36 COMMAND_MAX=37 MAGIC_REQ="\0REQ" MAGIC_RES="\0RES" 

throw() {
	echo Exception: "$@" >&2
	exit 1
}

raw_gearman_packet() {
   local reqres
   local command
   local function=''
   local data=''
	local packet_type
	local no_data=0
	local response=

   while (( $# )); do
      case "$1" in 
         --req )
            reqres="REQ"
            ;;
         --res )
            reqres="RES"
            ;;
         --command )
            command="COMMAND_$2"
            command="${!command}"
				[ "$command" -gt 0 ] || throw "\$command was empty or non-integer"
				printf -v packet_type '\\0\\0\\0\\%03o' $command
            shift
            ;;
         --job | --function )
            function="$2"
            shift
            ;;
			--response )
				response=1
				;&
         --data )
            if (( $# == 2 )); then
               data="$2"
               shift
            else
               data=()
               while (( $# > 1 )); do
                  data+=( "$2" )
                  shift
               done
            fi
            ;;
      esac
      shift
   done

   # chr   printf \\$(printf '%03o' $1)
   # ord   printf '%d' "'$1"
   # function decToBin { echo "ibase=10; obase=2; $1" | bc; }
	local hex
   local _packet_length
   _packet_length=0
   (( _packet_length += ${#function} ))
	if [ -n "$data" ]; then
		(( _packet_length += ${#data} ))
		(( _packet_length += 2 ))
		(( response )) && (( _packet_length-- ))
	fi
   printf -v hex '%08x' $_packet_length
	local packet_length=""
	while (( ${#hex} )); do
		packet_length+="\\x${hex:0:2}"
		hex="${hex:2}"
	done
	# printf -v hex '%b' $(printf '%08x' $_packet_length | sed 's/../\\\x&/g')
	# echo "Packet Length: ${_packet_length} hex: $hex"
	
	printf '%b%b%b%b'               "\0$reqres" \
											  "$packet_type" \
											  "$packet_length" \
											  "$function" 
	if [ -n "$data" -a -z "$response" ]; then
		printf '%b%b%b' 				  "\0" \
											  "\0" \
											  "${data[@]}" 
		else if [ -n "$data" ]; then
			printf '%b%b'				  "\0" \
											  "${data[@]}" 
		fi

	fi
}

raw_gearman_worker_register() {
	raw_gearman_packet --req --command CAN_DO --function "$1" --no-data >&$FD	|| throw $FUNCNAME "Couldn't write to gearman socket"
}

raw_gearman_worker_grab_job() {
	raw_gearman_packet --req --command GRAB_JOB --no-data >&$FD	|| throw $FUNCNAME "Couldn't write to gearman socket"
}

raw_gearman_worker_pre_sleep() {
	raw_gearman_packet --req --command PRE_SLEEP --no-data >&$FD || throw $FUNCNAME "Couldn't write to gearman socket"
}

raw_gearman_worker_work_complete() {
	raw_gearman_packet --req --command WORK_COMPLETE --job "$1" --data "$2" >&$FD || throw $FUNCNAME "Couldn't write to gearman socket"
}



raw_gearman_unused_but_useful() {
	declare -r HEX_DIGITS="0123456789ABCDEF"

	dec_value=$1
	hex_value=""

	until [ $dec_value == 0 ]; do

		 rem_value=$((dec_value % 16))
		 dec_value=$((dec_value / 16))

		 hex_digit=${HEX_DIGITS:$rem_value:1}

		 hex_value="${hex_digit}${hex_value}"

	done

	echo -e "${hex_value}"
}

raw_gearman_get_result() {
	local FD
	FD=$1
	el=0
	while (( el == 0 )); do
		echo Waiting for input...

		# read 1 character (which will be \x00) so we can use a timeout
		read -r -u $FD $GEARMAN_TIMEOUT -n 1	|| throw $FUNCNAME "Couldn't read from gearman socket ($?)"
		echo Data ready, calling dd...
		array="00$( dd bs=1 count=11 <&$FD 2>/dev/null | xxd -p )"
		el=$?
		echo -n Completed short dd....
		echo "${array[@]}"
		# Completed dd....005245530000000800000031
		response=$(( 0x${array:8:8} ))
		length=$(( 0x${array:16:8} ))
		echo -n "Response: ${COMMANDS[$response]%% *} ($response)  "
		echo "Length: " $length
		if (( $length )); then
			# array=$( echo $( dd bs=1 count=$length <&$FD | xxd -p ) | sed 's/ //g')
			array=""
			while read; do
				array+=$REPLY
			done  < <( dd bs=1 count=$length <&$FD 2>/dev/null | xxd -p )
			# echo Completed long dd.... "${array}"
		fi

		case $response in 
			$COMMAND_JOB_CREATED )
				# dd bs=1 count=$length <&$FD | xxd
				;;
			$COMMAND_WORK_COMPLETE )
				# read -r -u $FD -t 10 -a REPLY -n $length -d $'\0'	|| throw "Couldn't read from gearman socket"
				# array="$( dd bs=1 count=$length <&$FD | xxd -i )"
				# el=$?
				printf -v hex '%b' $(echo -n "$array" | sed 's/../ \\\x&/g')
				echo job "$hex"
				hex_len="${#hex}"
				(( hex_len = 2 + hex_len * 2 ))
				printf -v result '%b' $(echo -n "${array:$hex_len}") #  | sed 's/../ \\\x&/g')
				array="${result##*x00}"
				array="${array// }"
				echo what "$array"
				REPLY=$( echo "$array" | xxd -r -p )
				# echo "${array[@]}"
				echo "[$FD] $REPLY"
				return 0
				;;
			* )
				REPLY=$( echo "$array" | xxd -r -p )
				XXD="$array"
				return $response
		esac
	done
}

function _raw_gearman_stack_pop() {
	open /dev/tcp/chips3.nt4.com/4730 rw || throw "Couldn't open connection to gearman server"
	raw_gearman_packet --req --command SUBMIT_JOB --function Stack --data '{"operation":"shift","stackname":"'"${1}"'"}' >&$FD	|| throw "Couldn't write to gearman socket"
	raw_gearman_get_result $FD
	# echo "Result: $REPLY"
	close $FD
}

RAW_GEARMAN_FD=
export RAW_GEARMAN_FD
function raw_gearman_stack_push() 
{
	raw_gearman_stack_ push "$@"
	return
}
function raw_gearman_stack_unshift() 
{
	raw_gearman_stack_ unshift "$@"
	return
}
function raw_gearman_stack_pop() 
{
	raw_gearman_stack_ pop "$@"
	return
}
function raw_gearman_stack_() 
{
	test -n "$RAW_GEARMAN_FD" \
		&& FD=$RAW_GEARMAN_FD \
		|| open /dev/tcp/chips3.nt4.com/4730 rw || throw "Couldn't open connection to gearman server"
	local operation="$1"
	shift

	data='{"operation":"'$operation'","stackname":"'"${1}"'","value":'"${2:-null}"'}'
	# raw_gearman_packet --req --command SUBMIT_JOB --function Stack --data "$data" | xxd
	raw_gearman_packet --req --command SUBMIT_JOB --function Stack --data "$data" >&$FD	|| throw "Couldn't write to gearman socket"
	raw_gearman_get_result $FD > /dev/null
	echo "[$FD] $REPLY" >&2
	# echo "$2"
	# echo "Result: $REPLY"
	RAW_GEARMAN_FD=$FD
	# close $FD
}
# "command":"facebook.gear.zynga.add.iim","proxy":"${IP}:9999","data":{"account":{"username":"${EMAIL}","password":"${PASS}","proxy":"${IP}:9999"}}}
# raw_gearman_stack_push YahooGeneric "\"command\":\"facebook.gear.zynga.add.iim\",\"proxy\":\"${IP}:9999\",\"data\":{\"account\":{\"username\":\"${EMAIL}\",\"password\":\"${PASS}\",\"proxy\":\"${IP}:9999\"}}}"

# vim: set ts=3 sts=0 sw=3 noet:
