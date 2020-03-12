#!/bin/bash

# https://en.wikipedia.org/wiki/Kilobyte
FORMAT() {
	SUFFIX=" kMGTPEZY"
	AMOUNT="$1"
	while (( AMOUNT > 4096 )); do
		SUFFIX=${SUFFIX:1}
		(( AMOUNT /= 1000 ))
	done
	printf "%4s %4s\n" "$AMOUNT" "${SUFFIX:0:1}B/s"
}

CONTINUOUS() {
while true
do
	LINE=`/sbin/ifconfig -a | fgrep RX | head -2 | tail -1`
	IFS=" :" SPLIT=( $LINE )
	RX="${SPLIT[2]}" TX="${SPLIT[7]}"

	if [ -n "$LASTRX" ]; then
		(( THIS_TX = ( RX - LASTRX ) * 8 ))
		(( THIS_RX = ( TX - LASTTX ) * 8 ))
		printf "%8s %8s\n" "$( FORMAT "$THIS_RX" )" "$( FORMAT "$THIS_TX" )"
	fi

	LASTRX="$RX" LASTTX="$TX"
	sleep 1
done
}

SET_BPS_START() {
	LINE=`/sbin/ifconfig -a | fgrep RX | head -2 | tail -1`
	IFS=" :" SPLIT=( $LINE )
	BPS_RX="${SPLIT[2]}" BPS_TX="${SPLIT[7]}" BPS_SECONDS="$SECONDS"
}

GET_BPS() {
	LAST_BPS_RX="$BPS_RX"
	LAST_BPS_TX="$BPS_TX"
	LAST_BPS_SECONDS="$BPS_SECONDS"
	SET_BPS_START
	(( SECONDS_DIFF = BPS_SECONDS - LAST_BPS_SECONDS ))
	# (( THIS_TX = ( BPS_RX - LAST_BPS_RX ) * 8 ))
	# (( THIS_RX = ( BPS_TX - LAST_BPS_TX ) * 8 ))
	(( THIS_RX = ( BPS_RX - LAST_BPS_RX )  ))
	(( THIS_TX = ( BPS_TX - LAST_BPS_TX )  ))
	(( THIS_TX /= SECONDS_DIFF ))
	(( THIS_RX /= SECONDS_DIFF ))
	printf "RX: %-12s    TX: %-12s\n" "$( FORMAT "$THIS_RX" )" "$( FORMAT "$THIS_TX" )"
}

DEMO() {
SET_BPS_START
sleep 1
while true
do
	sleep 1
	GET_BPS $SECONDS
	sleep 5
	GET_BPS $SECONDS
done
}

SET_BPS_START
