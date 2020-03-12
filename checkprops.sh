#!/usr/bin/env bash

# dev-tcp.sh: /dev/tcp redirection to check Internet connection.

# Script by Troy Engel.
# Used with permission.

. ../bash/fds.linux.inc.sh
. ../bash/json.sh
. ../bash/explode.inc.sh
. ../bash/array_shift.inc.sh

 
TCP_HOST=podxen.stinkyrabbit.com  # RoomLocker
# TCP_HOST=192.168.46.4
TCP_PORT=45678                      # Port
HOST="test"
EXAMPLE_STRING="podGetRoomLock {\"casinoId\":\"Live\",\"expiry\":0.00002,\"roomIdArray\":[\"$HOST\"]}"
SHOWWRITE=1
LF=$'\x0a'

podPropertySet() {
	local __FUNCTION__="${FUNCNAME[@]:0:1}"
	local key=$1
	local val=$2
	local -A AA
	AA[${key}]="${val}"
	aaray2json_ref AA

	open /dev/tcp/$TCP_HOST/$TCP_PORT "r+"
	write $FD "${__FUNCTION__} ${JSON}${LF}"
	fgets $FD
	# cat <&11
	close $FD

	return
}

podPropertyGet() {
	local __FUNCTION__="${FUNCNAME[@]:0:1}"
	local -a keys=( "$@" )
	local -a AA
	AA=("${keys[@]}")
	aaray2json_ref AA

	open /dev/tcp/$TCP_HOST/$TCP_PORT "r+"
	write $FD "${__FUNCTION__} {\"keys\":${JSON}}${LF}"
	fgets $FD
	close $FD

	return
}

indirect_reference() {
	echo "The variable ${1} is equal to ${!1}"
}

while IFS= read 
do
	echo "$REPLY <<\n";
done < <( declare -p )

# exit

STATE_TEST=7
indirect_reference STATE_TEST
podPropertySet checkprops.testkey checkprops.testval

podPropertySet checkprops.test.sls24.env "$( declare -p )"
podPropertyGet checkprops.test.sls24.env 
