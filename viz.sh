#!/usr/bin/env bash

. ../gsm/bash/includer.inc.sh arrays.inc.sh

explode_into() {
   local c=$#
   (( c < 2 )) &&
   {
      echo missing parameters 
      return 1
   }
   local delimiter="$1"
   local string="$2"
	shift 2
	local into=( $@ )

   local delimiter_len=${#delimiter}
   local tmp_delim=$'\x07'
   local delin=${string//$delimiter/$tmp_delim}
   pushifs $'\x07'
   EXPLODED=($delin)
   popifs

	local v=0
	for i in ${into[@]}
	do
		local $i && upvar $i "${EXPLODED[$v]}"
		(( v++ ))
	done

}

declare -a vars=(proto recvq sendq local foreign state program port)
declare -a vars=(local foreign program)

						unset portlist
						declare -a portlist='()'
						while read proto recvq sendq local foreign state program; do
							program=${program##*/}
							explode_into : $local local localport
							explode_into : $foreign foreign foreignport
							
							(( program + 1 != 1 )) > /dev/null 2>&1 && continue
							[[ $state != ESTABLISHED ]] && continue
							[[ $program == - ]] && continue

							# port="${local##*:}"

							false && 
							for i in ${vars[@]}
							do
								printf "%10s:\t%15s\t" $i ${!i}
							done
							printf '"%s"->"%s"\n' $local $foreign
						done < <( netstat -tnp )
