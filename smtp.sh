#!/bin/bash
MAIL_FROM="spamtrak@bash.spamtrak.org"
RCPT_TO="spamtrak@bash.spamtrak.org"
MESSAGE=message.txt
SMTP_PORT=25                      
SMTP_DOMAIN=${RCPT_TO##*@}

index=1
while read PRIORITY RELAY
do
	RELAY[$index]="${RELAY%.}"
	((index++))
done < <( dig +short MX $SMTP_DOMAIN )

RELAY_COUNT=${#RELAY[@]}
SMTP_COMMANDS=( "HELO $HOSTNAME" "MAIL FROM: <$MAIL_FROM>" "RCPT TO: <$RCPT_TO>" "DATA" "." "QUIT" )
SMTP_REPLY=([25]=OK [50]=FAIL [51]=FAIL [52]=FAIL [53]=FAIL [54]=FAIL [55]=FAIL [45]=WAIT [35]=DATA [22]=SENT)

for (( i = 1 ; i < RELAY_COUNT ; i++ ))
do
	SMTP_HOST="${RELAY[$i]}"
	echo "Trying relay [$i]: $SMTP_HOST..."
	exec 5<>/dev/tcp/$SMTP_HOST/$SMTP_PORT || continue
	read HELO <&5
	echo GOT: $HELO
	for COMMAND_ORDER in 0 1 2 3 4 5 6 7
	do
		OUT=${SMTP_COMMANDS[COMMAND_ORDER]}
		echo SENDING: $OUT
		echo -e "$OUT\r" >&5

		read -r REPLY <&5
		echo REPLY: $REPLY
		# CODE=($REPLY)
		CODE=${REPLY:0:2}
		ACTION=${SMTP_REPLY[CODE]}
		case $ACTION in
			WAIT )		echo Temporarily Fail
							break
							;;
			FAIL )		echo Failed
							break
							;;
			OK )			;;
			SENT )		exit 0
							;;
			DATA )		echo Sending Message: $MESSAGE
# From: Sfinktah Bungholio <sfinktah@pplsimbrowsers.spamtrak.org>
# To: Jeffrey Marrison <sfinktah@pplsimbrowsers.spamtrak.org>
# Subject: My Accolade
							cat $MESSAGE >&5
							echo -e "\r" >&5
							;;
			* )         echo Unknown SMTP code $CODE
							exit 2
		esac
	done
done
