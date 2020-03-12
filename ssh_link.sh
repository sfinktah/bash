#!/bin/bash
# . ~/.ssh-agent
if (( $# < 3 )); then
	echo Usage: "$0" "<user>" "<server>" "<port>" "[local port]"
	exit 1
fi
SSH=/usr/bin/ssh
SSH_USER=$1
shift
SSH_HOST=$1
LOCAL_PORT=${3-:2}
REMOTE_PORT=$2
REMOTE_ADDR=localhost
LOCAL_ADDR=localhost

#     -C      Requests compression of all data 
#     -f      Requests ssh to go to background just before command execution. 
#             port on the local side, optionally bound to the specified bind_address.  
#     -N      Do not execute a remote command.  This is useful for just forwarding ports (protocol version 2 only).
#     -n      Redirects stdin from /dev/null (actually, prevents reading from stdin).  This must be used when ssh is run in
#             the background. 
#     -q      Quiet mode.  Causes most warning and diagnostic messages to be suppressed.  Only fatal errors are displayed.
#     -L [bind_address:]port:host:hostport
#             Specifies that the given port on the local (client) host is to be forwarded to the given host and port
#     -R [bind_address:]port:host:hostport
#             Specifies that the given port on the remote (server) host is to be forwarded to the given host and port on the
#             local side.  This works by allocating a socket to listen to port on the remote side
#     -D [bind_address:]port
#             Specifies a local “dynamic” application-level port forwarding.  This works by allocating a socket to listen to
                               
SSH_OPTIONS="-fnNC"
SSH_LINK="-L $LOCAL_ADDR:$LOCAL_PORT:$REMOTE_ADDR:$REMOTE_PORT"

echo Connecting to $SSH_HOST...
$SSH $SSH_OPTIONS $SSH_LINK $SSH_USER@$SSH_HOST
