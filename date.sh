#!/bin/bash
# date-calc.sh
# Author: Nathan Coulter
# Used in ABS Guide with permission (thanks!).

MPHR=60    # Minutes per hour.
HPD=24     # Hours per day.

diff () {
        printf '%s' $(( $(date -u -d"$TARGET" +%s) -
                        $(date -u -d"$CURRENT" +%s)))
#                       %d = day of month.
}

now() {
	NOW=$(date -u '+%F %T.%N %Z')
	printf '%s' "$NOW"
}

elapsed () {
	CURRENT="$1"
	TARGET="$2"

	# %F = full date, %T = %H:%M:%S, %N = nanoseconds, %Z = time zone.

	echo $CURRENT
	echo $TARGET

	# printf '\nOn %s at %s, there were\n'  $(date -u -d"$CURRENT" +%F) $(date -u -d"$CURRENT" +%T)
	DAYS=$(( $(diff) / $MPHR / $MPHR / $HPD ))
	CURRENT=$(date -u -d"$CURRENT +$DAYS days" '+%F %T.%N %Z')
	HOURS=$(( $(diff) / $MPHR / $MPHR ))
	CURRENT=$(date -u -d"$CURRENT +$HOURS hours" '+%F %T.%N %Z')
	MINUTES=$(( $(diff) / $MPHR ))
	CURRENT=$(date -u -d"$CURRENT +$MINUTES minutes" '+%F %T.%N %Z')
	(( DAYS )) &&  printf '%s days, ' "$DAYS"
	(( HOURS )) &&  printf '%s hours, ' "$HOURS"
	(( MINUTES )) && printf '%s minutes, and ' "$MINUTES" 
	printf '%s seconds ' "$(diff)"
}
