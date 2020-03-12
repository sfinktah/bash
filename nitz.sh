#!/bin/bash


process_nitz() {
	# 	•	1: Full name for network 
	#	•	2: Short name for network 
	#	•	3: Local time zone (expressed in 15 minute signed int)
	#	•	4: Universal time and local time zone 
	#	•	5: LSA identity 
	#	•	6: Network Daylight Saving Time

	#  <gsm5>       +WIND: 15,1,"AT&T",2,"AT&T",3,"-28",4,"12/04/28,02:50:33-28",6,"1"

	local s=$1
	s=${s#+WIND: }
	s=${s#15,}
	s+=,
	explode '",' "$s"
	declare -p EXPLODED


	local key
	local value
	for pair in ${EXPLODED[@]}
	do
		echo pair:  "$pair"
		explode ',"' "$pair"
		key=${EXPLODED[0]}
		value=${EXPLODED[1]}
		printf "%s: %s\n" "$key" "$value"
	done
}

process_nitz '+WIND: 15,1,"AT&T",2,"AT&T",3,"-28",4,"12/04/28,02:50:33-28",6,"1"'
