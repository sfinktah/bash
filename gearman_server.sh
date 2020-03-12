#!/usr/bin/env bash
BASEDIR=$(cd `dirname $0` && pwd) ; cd $BASEDIR
. $BASEDIR/json.sh
. $BASEDIR/raw_gearman.sh
. $BASEDIR/arrays.inc.sh

GEARMAN_SERVER=chips3.nt4.com


GEARMAN_TIMEOUT=

function do_job	# job_handle function_name work_data
{
	job_handle="$1"
	function_name="$2"
	work_data="$3"

	raw_gearman_packet --req --command WORK_COMPLETE --function "$job_handle" --response "done" | xxd -c 4 -g 1 # >&$FD	|| throw "Couldn't write to gearman socket"
	raw_gearman_packet --req --command WORK_COMPLETE --function "$job_handle" --response "done" >&$FD	|| throw "Couldn't write to gearman socket"
}



echo Connecting to $GEARMAN_SERVER
open /dev/tcp/$GEARMAN_SERVER/4730 rw || throw "Couldn't open connection to gearman server"
echo Sending CAN_DO
raw_gearman_packet --req --command CAN_DO --function TorrentReady >&$FD	|| throw "Couldn't write to gearman socket"
echo Sending GRAB_JOB
raw_gearman_packet --req --command GRAB_JOB >&$FD	|| throw "Couldn't write to gearman socket"
while true
do
	echo Waiting for reply
	raw_gearman_get_result $FD 
	el=$?
	case $el in
		6 )	# NOOP
			echo Sending GRAB_JOB
			raw_gearman_packet --req --command GRAB_JOB >&$FD	|| throw "Couldn't write to gearman socket"
			;;
		10 )	# NO_JOB
			echo Sending PRE_SLEEP
			raw_gearman_packet --req --command PRE_SLEEP >&$FD	|| throw "Couldn't write to gearman socket"
			;;
		11 ) # JOB_ASSIGN
			echo Received JOB_ASSIGN
			# Received JOB_ASSIGN: H:ip-208-109-177-188.ip.secureserver.net:46970570TorrentReady{"operation":"76853","stackname":""}
			#			Job Server -> Worker
			#			00 52 45 53                \0RES        (Magic)
			#			00 00 00 0b                11           (Packet type: JOB_ASSIGN)
			#			00 00 00 14                20           (Packet length)
			#			48 3a 6c 61 70 3a 31 00    H:lap:1\0    (Job handle)
			#			72 65 76 65 72 73 65 00    reverse\0    (Function)
			#			74 65 73 74                test         (Workload)
			local -a all_items=()
			while read line
			do
				line="${line//,/}"
				all_items+=( $line )
			done  < <(echo "$XXD" | xxd -r -p | xxd -i )

			null_replaced="${all_items[@]//0x00/0x07}"
			all_items_text=$( echo " ${null_replaced// 0x}" | xxd -p -r )
			explode $'\x07' "$all_items_text"
			job_handle=${EXPLODED[0]}
			function_name=${EXPLODED[1]}
			work_data=${EXPLODED[2]}
			declare -p job_handle function_name work_data
			do_job "$job_handle" "$function_name" "$work_data"
			raw_gearman_packet --req --command GRAB_JOB >&$FD	|| throw "Couldn't write to gearman socket"
			;;
		* )
			echo Received unknown response from server "($el) $REPLY"
	esac
done


# read -r -u $FD $GEARMAN_TIMEOUT -n 1	|| throw $FUNCNAME "Couldn't read from gearman socket ($?)"
# echo Data ready, calling dd...
# array="00$( dd bs=1 count=5 <&$FD 2>/dev/null | xxd -p )"
# echo Got: "$array"
close $FD

if [[ $REPLY == "false" ]]; then
	echo "Gearman: $REPLY"  >&2
	exit 1
fi

echo "Gearman Returned: $REPLY" >&2
if [[ ${REPLY:0:1} == '"' && ${REPLY:1:1} != "{" ]]; then
	# Assume we have a single username
	USERNAME="${REPLY//\"}"	# "
	REPLY="$USERNAME"
fi
# vim: set ts=3 sts=0 sw=3 noet:
