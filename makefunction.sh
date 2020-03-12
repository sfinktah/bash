#!/usr/bin/env bash

# makes function from source file
# $1 - function name
# $2 - file name, or blank for stdin
makefunction() {
	# if [ $2 == "-" ]; then
	#	cat > 

	echo -e "$1() {\n" > /tmp/$$
	cat $2 >> /tmp/$$
	echo "}" >> /tmp/$$
	. /tmp/$$
	rm /tmp/$$
}

runmakefunction() {
	fn="_$RANDOM"
	makefunction $fn 
	$fn 
}

makeloop() {
	while :; do
		. $1
	done
}


