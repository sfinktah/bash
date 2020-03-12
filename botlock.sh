#!/usr/bin/env bash

. include fds
 
TCP_HOST=roomlock.stinkyrabbit.com  # RoomLocker // 203.26.88.253 : 192.168.46.14
TCP_PORT=45678                      # Port 
SHOWWRITE=1
LF=$'\x0a'

# 14290: RoomLock-EncodeRequest: podGetRoomLock {"casinoId":"RunningBots","roomIdArray":["brocklawrence1241@mail.com"],"expiry":0.04166667}
# 14287: RoomLock-EncodeRequest: podReleaseRoomLock {"casinoId":"RunningBots","roomId":"aberg8300@yahoo.com"}

podGetRoomLock() {
	local BOT=$1

	EXAMPLE_STRING="podGetRoomLock {\"casinoId\":\"RunningBots\",\"expiry\":0.00006,\"roomIdArray\":[\"$BOT\"]}"

   echo Connecting to "$TCP_HOST:$TCP_PORT..." >&2
   open /dev/tcp/$TCP_HOST/$TCP_PORT "r+"								 || exec date +"Failed to connect"

	echo Writing to socket... >&2
	write $FD "$EXAMPLE_STRING$LF"										 || exec date +"Failed to write"

	echo Reading from socket... >&2
	fgets $FD																	 || exec date +"Failed to read"								

	echo Received: "'$REPLY'" >&2
	[[ $REPLY == -1 ]]														 && echo Bot is blocked >&2 \
																					 || echo Bot "$REPLY" is available >&2
	echo Closing socket... >&2
	close $FD																	 || exec date +"Failed to close"

	[[ $REPLY == -1 ]] && return 1
	return 0
} # 2>/dev/null # uncomment to shut this up

if podGetRoomLock brocklawrence1241@mail.com
then
	echo Good to go! >&2
else
	echo Bot is running >&2
fi

# vim: set ts=3 sts=64 sw=3 foldmethod=marker noet :
