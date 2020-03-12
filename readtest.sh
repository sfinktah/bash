#!/usr/bin/env bash
. arrays.inc.sh
while true
do
	# while read byte rest
	while read line
	do
		line="${line//,/}"
		# items=( $line )
		all_items+=( $line )
		

		# an amusing side excerise, high inefficient#{{{
		#		echo "$byte -- $rest"
		#		while read _byte _rest < <( echo "$rest" )
		#		do
		#			echo "$_byte -- $_rest"
		#			[ -z "$_rest" ] && break
		#			rest="$_rest"
		#		done#}}}
	done < <( cat readtest.txt )
	break
done
null_replaced="${all_items[@]//0x00/0x07}"
all_items_text=$( echo " ${null_replaced// 0x}" | xxd -p -r )
explode $'\x07' "$all_items_text"
job_handle=${EXPLODED[0]}
function_name=${EXPLODED[1]}
work_data=${EXPLODED[2]}

declare -p all_items all_items_text EXPLODED job_handle function_name work_data
