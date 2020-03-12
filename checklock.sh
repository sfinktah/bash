#!/usr/bin/env bash

. include json fds

# . ../bash/fds.sh
# . ../bash/json.sh
# . ../bash/explode.inc.sh
# . ../bash/array_shift.inc.sh

 
TCP_HOST=roomlock.stinkyrabbit.com  # RoomLocker // 203.26.88.253 : 192.168.46.14
TCP_PORT=45678                      # Port 
BOT="brocklawrence1241@mail.com"
# EXAMPLE_STRING="podGetRoomLock {\"casinoId\":\"Live\",\"expiry\":0.00006,\"roomIdArray\":[\"$HOST\"]}"
EXAMPLE_STRING="podGetRoomLock {\"casinoId\":\"RunningBots\",\"expiry\":0.00006,\"roomIdArray\":[\"$BOT\"]}"
SHOWWRITE=1
LF=$'\x0a'

# 14290: RoomLock-EncodeRequest: podGetRoomLock {"casinoId":"RunningBots","roomIdArray":["brocklawrence1241@mail.com"],"expiry":0.04166667}
# 14287: RoomLock-EncodeRequest: podReleaseRoomLock {"casinoId":"RunningBots","roomId":"aberg8300@yahoo.com"}

podGetRoomLock() {
	local __FUNCTION__="${FUNCNAME[@]:0:1}"
	local casino=$1
	shift
	local -a room=( "$@" )
	local -A AA								# Declare 'AA' as an associative array

	AA["casinoId"]=$casino
	AA["roomIdArray"]=${room[@]}				# Bash can't properly handle multi-dimensional arrays
	aaray2json_ref AA

   echo Connecting to "$TCP_HOST:$TCP_PORT..." >&2
   open /dev/tcp/$TCP_HOST/$TCP_PORT "r+" || exec date +"Failed to connect"
	# write $FD "${__FUNCTION__} ${JSON}${LF}"
	echo Writing to socket... >&2
	write $FD "$EXAMPLE_STRING$LF" || exec date +"Failed to write"
	echo Reading from socket... >&2
	# cat <&$FD
	fgets $FD || exec date +"Failed to read"								
	echo Received: "'$REPLY'" >&2
	[[ $REPLY == -1 ]] \
			&& echo Bot is blocked >&2 \
			|| echo Bot "$REPLY" is available >&2
	echo Closing socket... >&2
	close $FD || exec date +"Failed to close"
	[[ $REPLY == -1 ]] && return 1
	return 0
}

if podGetRoomLock brocklawrence1241@mail.com
then
	echo Good to go! >&2
else
	echo Bot is running >&2
fi
