#!/usr/bin/env bash
. include json raw_gearman

GEARMAN_SERVER=chips3.nt4.com
GEARMAN_TIMEOUT="-t 10"
POPSHIFT=push
QUEUE=PodTotal
VALUE=123456789
# VALUE=$1

open /dev/tcp/$GEARMAN_SERVER/4730 rw || 
   throw "Couldn't open connection to gearman server"
raw_gearman_packet --req --command SUBMIT_JOB \
	--function Stack --data \
'{"operation":"'$POPSHIFT\
'","stackname":"'"$QUEUE"\
'","value":"'$VALUE'"}' >&$FD || 
      throw "Couldn't write to gearman socket"
raw_gearman_get_result $FD
close $FD

if [[ $REPLY == "false" ]]; then
	echo "Gearman: $REPLY" >&2
	exit 1
fi

echo "Gearman: $REPLY" >&2
exit 0

# vim: set ts=3 sts=64 sw=3 noet:
