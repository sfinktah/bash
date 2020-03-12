#!/usr/bin/env bash
# dev-tcp.sh: /dev/tcp redirection to check Internet connection.

# Script by Troy Engel.
# Used with permission.

. ../bash/fds.sh
. ../bash/json.sh
. ../bash/explode.inc.sh
. ../bash/array_shift.inc.sh

 
TCP_HOST=roomlock.stinkyrabbit.com  # RoomLocker
TCP_PORT=45678                      # Port 
HOST="test"
EXAMPLE_STRING="podGetRoomLock {\"casinoId\":\"Live\",\"expiry\":0.00002,\"roomIdArray\":[\"$HOST\"]}"
SHOWWRITE=1
LF=$'\x0a'

podGetRoomLock() {
	local __FUNCTION__="${FUNCNAME[@]:0:1}"
	local casino=$1
	shift
	local -a room=( "$@" )
	local -A AA								# Declare 'AA' as an associative array

	AA["casinoId"]=$casino
	AA["roomIdArray"]=${room[@]}				# Bash can't properly handle multi-dimensional arrays
	aaray2json_ref AA

	open /dev/tcp/$TCP_HOST/$TCP_PORT "r+"

	write $FD "${__FUNCTION__} ${JSON}${LF}"
	fgets $FD 								# echo $REPLY	# is echoed by fgets (how annoying, I know)
	close $FD

	return
}

indirect_reference() {
	echo "The variable ${1} is equal to ${!1}"
}

STATE_TEST=7
indirect_reference STATE_TEST
podGetRoomLock CasinoTest TestRoom
