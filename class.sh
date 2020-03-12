#!/usr/bin/env bash

. upvars.inc.sh
. classes.inc.sh

alpha.tostring() {
	scope
	echo "$this" "string is" "$1"
}

alpha.xoutput() {
	scope
	$this.tostring magic
}

beta.tostring() {
	scope
	echo "$this" "string is" "$1"
}

beta.output() {
	scope
	tostring "$@"
}

function theta {
	scope
	name=$1
	eval "$( echo '
					theta.tostring() {
						scope
						echo "$this" string is "$1"
					} 
	' | sed "s/theta/$name/" )"
}

endclass

theta inst
inst.tostring hello
