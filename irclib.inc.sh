#!/bin/bash
# http://tldp.org/LDP/abs/html/refcards.html#AEN22518	REFERENCE CARDS
[ -f /etc/hostname ] && HOSTNAME=`cat /etc/hostname`
[ -z "$HOSTNAME" ] && {
	echo "$0" "-" No hostname defined
	exit 1
}
. include upvars irc.inc upvars array.class 

OURNICK="ircproxybot"
SERVER_ADDR=irc
SERVER_PORT=7776
IRC_NICK=${HOSTNAME//[^a-zA-Z0-9]/_}
IRC_PASS=fuckzynga

HAVEOP=0

# . date.sh
# . rfc1459.inc.sh


function_trap_term() {
	write "QUIT :SIGTERM (Are we rebooting?)"
	echo "SIGTEM" >> $0.$$.log
	exit 13
}

function_trap() {
	echo "^C (SIGINT) detected..."

	write "QUIT :^C (SIGINT)"
	echo "SIGINT" >> $0.$$.log
	exit 13
}

function_exists() {
	declare -f -F $1 > /dev/null
	return $?
}

number_format() {
	dollar_amt=$1
	length=`echo $dollar_amt | awk '{ print length($0) }'`
	mod=`expr $length % 3`
	div3=`expr $length / 3`
	if [[ $mod -ne 0 ]]
	then
		dollar_pt0=`echo $dollar_amt | cut -c 1-$mod`
	fi

	dollar_fin=`echo "${dollar_pt0}"`

	modp1=`expr $mod + 1`
	incr=`expr $mod + 3`

	i="0"
	while [ $i -lt $div3 ]
	do
		mySub=`echo $dollar_amt | cut -c ${modp1}-${incr}`
		if [[ $modp1 -ne 1 ]]
		then
			dollar_fin=`echo ${dollar_fin},${mySub}`
		else
			dollar_fin=`echo ${dollar_fin}${mySub}`
		fi
		incr=`expr $incr + 3`
		modp1=`expr $modp1 + 3`
		((i++))
	done
	dollar_fin=`echo $dollar_fin`
	echo -n $dollar_fin
}



write() {
	echo ">>> " "$@"
	echo "$@" >&5
}

pipe_to_privmsg() {
	[ -n "$1" ] && TO="$1" || TO="$FROM"
	#           IFS=: read -r header value <<< "$mail"
	while IFS= read -r LINE
	do
		# echo "$LINE"
		write NOTICE $TO ":$LINE"
	done
}


away() {
	if [ -z "$1" ]
	then
		write "AWAY"
	else
		write "AWAY" ":$@"
	fi
}

# [ 332 ] :irc5.foonet.com 332 ec #proxies :BashMan's Lair
on332() {
	OURNICK="$3"
	# [ -n "$INTERVAL" ] && printf 'Was offline for %s' "$INTERVAL" | pipe_to_privmsg
}

# Ops
# [ MODE ] :cyrus!cyrus@rox-E4FDA80C.gqle1.lon.bigpond.net.au MODE #proxies +o ec
onMODE() {
	CHANNEL=$3
	MODE=$4
	NICK=$5
	# echo MODE: Channel:$3 Mode:$4 Nick:$5 OurNick:$6
	if [ "$MODE" == "+o" -a "$NICK" == "$OURNICK" ]
	then
		HAVEOP=1
		write "WHO $CHANNEL"
	fi
}



# [ 352 ] :irc5.foonet.com 352 ec #proxies chips25 proxy irc5.foonet.com chips25 H@ :0 chips25
# [ 352 ] :irc5.foonet.com 352 ec #proxies c14 proxy irc5.foonet.com c14 H@ :0 c14
# [ 352 ] :irc5.foonet.com 352 ec #proxies Pod B00D6373.D2380C72.C7E358E6.IP irc6.foonet.com Pod H :1 Pod
# [ 352 ] :irc5.foonet.com 352 ec #proxies win1 proxy irc5.foonet.com win1 H :0 win1
# [ 315 ] :irc5.foonet.com 315 ec #proxies :End of /WHO list.
on315() {
	# daemon_watch | pipe_to_privmsg "#proxies" &
	:
}
on352() {
	CHANNEL=$4
	USER=$5
	VHOST=$6
	SERVER=$7
	NAME=$8
	STATUS=$9
	
	if [ "$STATUS" == "H" -a "$VHOST" == "proxy" ]
	then
		addBot "$NAME"
		write "MODE $CHANNEL +o $NAME"
	fi
}

# [ JOIN ] :cyrus!cyrus@rox-E4FDA80C.gqle1.lon.bigpond.net.au JOIN :#proxies
onJOIN() {

	FROM_ADDR="$( split_prefix ADDR "$1" )"
	FROM_NICK="$( split_prefix NICK "$1" )"

	CHANNEL=$( strip_colon "$3" )
	if [ "$FROM_ADDR" == "proxy" ]; then
		addBot "$FROM_NICK"
		if [ "$HAVEOP" -eq "1" ]; then
			write "MODE $CHANNEL +o $FROM_NICK"
		fi
	fi
}

whois() {
	write "WHOIS cyrus"
	# [ 313 ] :irc5.foonet.com 313 ec cyrus :is a Network Administrator
}

in_array() {
   needle="$1"
   shift

   while [ $# -gt 0 ]; do
      if [ "$needle" == "$1" ]; then
         return 0
      fi
      shift
   done
   return 1
}

isAdmin() {
	in_array "$1" "${ADMIN[@]}" 
}

on313() {
	WHO=$4
	isAdmin "$WHO" ||
		ADMINS=( "${ADMINS[@]}" "$WHO" )
}

# [ 353 ] :irc5.foonet.com 353 ec = #proxies :ec @chips7 @chips26 @chips23 @chips4 @chips5 @chips3 @centos8 servant tank ...
# "<channel> :[[@|+]<nick> [[@|+]<nick> [...]]]"
BOTS_B4_ME=0
on353() {
	shift 4
	CHANNEL=$1
	shift

	while shift 
	do
		HASH=${1:0:1}
		if [ "$HASH" = "#" ] 
		then
			# Channel Message
			USER=${1:1}
		elif [ "$HASH" = "+" ]
		then
			USER=${1:1}
		elif [ "$HASH" = "@" ]
		then
			USER=${1:1}
			addBot "$USER"
		else
			# Private Message
			USER=${1}
		fi

		echo Noticed user $USER
		(( BOTS_B4_ME ++ ))
	done
}

# [ 366 ] :irc5.foonet.com 366 ec #proxies :End of /NAMES list.
on366() {
	CHANNEL=$4
	# write "WHO $4"
}

# on251() if :; then					# just an alternate way of surrounding a function
# on251() {
# 	echo "base on251 called"
# 	write VHOST proxy wingtips
# 	write WATCH "+vpc_cw1zeg"
# 	write JOIN "#proxies"
# 	[[ $OURNICK == "ec" ]] && # [[ ${#knownBots[@]} == 0 ]] && 
# 		for bot in $known_bots
# 		do
# 			write WATCH "+$bot"
# 		done
# 	# write WATCH +cyrus
# }

on600() {
	addBot "$4"
	echo $4 has logged on
}

on601() {
	removeBot "$4"
	echo $4 has logged off
}

on604() {
	addBot "$4"
	echo $4 already online
}

on605() {
	removeBot "$4"
	# :irc5.foonet.com 605 ec vpc_cw1zeg * * 0 :is offline
	echo \"$4\" is offline
}



declare -A knownBots=() 
declare -A missingBots=() 
declare -A presentBots=()

addBot()
{
	echo "adding bot: $1"
	presentBots["$1"]="$1"
}

removeBot()
{
	unset presentBots["$1"]
}

onQUIT() {
	# not even sure this works
	echo "onQUIT: $@"
	return

	local WHO=$( split_prefix NICK "$1" )
	if [[ $WHO == $IRC_NICK ]]; then
		write NICK $IRC_NICK 
	fi

	shift 2
	MSG="$@"
	MSG=$( strip_colon "${MSG:1}" )
	declare -a MAR
	MAR=( $MSG )
	# Lowercase conversion: n=`echo $fname | tr A-Z a-z
	# PRIVMSG: "Quit: ^C (SIGINT)"

	removeBot "$WHO"
	case "${MAR[1]}" in
		Ping )	
			echo $WHO just timed out | pipe_to_privmsg
			;;
		* )
			echo $WHO just quit: $MSG | pipe_to_privmsg
	esac
}

onNOTICE() {
	# :cyrus!cyrus@rox-25E0BD4.gqle1.lon.bigpond.net.au NOTICE #wwii :This is a notice, you will be ponged to death.
	PREFIX="$1"
	FROM=$( split_prefix NICK "$1" )
	shift 3
	onPRIVMSG "$PREFIX" PRIVMSG "$FROM" "$@"
}
	
onPRIVMSG() {
	HASH=${3:0:1}
	if [ "$HASH" = "#" ] 
	then
		# Channel Message
		FROM=$3
	else
		FROM=$( split_prefix NICK "$1" )

		# Replace all matches of $substring with $replacement
		# ${string%%substring}	Strip longest match of $substring from back of $string
		# expr index "$string" $substring	Numerical position in $string of first character in $substring* that matches [0 if no match, first character counts as position 1]
		# expr match "$string" '$substring'	Length of matching $substring* at beginning of $string
	fi

	shift 3
	MSG="$@"
	MSG=${MSG:1}
	MAR=( ${MSG} )
	if [ "${MAR[0]%,}" == "$IRC_NICK" ]; then
		CMD=${MAR[1]}
		ARG=${MAR[2]}
	else
		CMD=${MAR[0]}
		ARG=${MAR[1]}
	fi

	# Lowercase conversion: n=`echo $fname | tr A-Z a-z
	echo PRIVMSG: \"$MSG\"
	case "${CMD}" in
		aldskjfhasdkjfh ) 
			echo test | pipe_to_privmsg
			;;
	esac
}

# if [ -n "$IRC_LAST_PACKET" ]
# then
# 	NOW=$(now)
# 	INTERVAL=$(elapsed "$IRC_LAST_PACKET" "$NOW")
# fi

main.loop() {
	# export 
	read -t 300 -u 5 -r REPLY 
	el=$?
	# printf "errorlevel: %2s  lenreply: %3s\n" $el "${#REPLY}"
	if [ "$el" -ne "0" ]
	then
		echo "Connection EOF/timeout Errorlevel $el" >> $0.$$.log
		return $el
	fi

	LEN=${#REPLY}
#	if [ "$LEN" -gt "0" ]
#	then
#		IRC_LAST_PACKET=$(now)
#		export IRC_LAST_PACKET
#	fi
	REPLY="${REPLY:0:$((LEN-1))}"
	declare -a RARRAY
	IFS=" " RARRAY=( $REPLY )
	PREFIX=${RARRAY[0]}
	CODE=${RARRAY[1]}
	# echo [ "$CODE" ] "$REPLY"

	case $PREFIX in
		PING )	unset RARRAY[0]
					write PONG "${RARRAY[@]}"
					;;
		ERROR )	# [ :Closing ] ERROR :Closing Link: sup_er_fragi[CPE-124-190-251-137.gqle1.lon.bigpond.net.au] (Ping timeout)
					echo "$REPLY"
					exit 1
					;;
		* ) 		function_exists on$CODE && on$CODE ${RARRAY[@]} || \
					case $CODE in #{{{
						# 251 )		write JOIN "#proxies"
						#				;;
						433 )			write NICK ${IRC_NICK}_$$
										;;
						NOTICE )		;;
						JOIN )		;;
						PRIVMSG )	
										# Unknown IRC code PRIVMSG
										# [ PRIVMSG ] :cyrus!cyrus@rox-E4FDA80C.gqle1.lon.bigpond.net.au PRIVMSG #proxies :hello idiot
										# [ PRIVMSG ] :cyrus!cyrus@rox-E4FDA80C.gqle1.lon.bigpond.net.au PRIVMSG ec :hello idiot
										# element_count=${#colors[@]}
										# Special syntax to extract number of elements in array.
										#     element_count=${#colors[*]} works also.
										#
										#  The "@" variable allows word splitting within quotes
										#+ (extracts variables separated by whitespace).
										#
										#  This corresponds to the behavior of "$@" and "$*"
										#+ in positional parameters. 


										onPRIVMSG ${RARRAY[@]}
										;;
						ERROR )		exit 0
										;;
						FAIL )		echo Failed
										break
										;;
						OK )			;;
						SENT )		exit 0
										;;
						"" )			echo Empty Reply, Exiting
										exit 0
										;;

						* )         C1={$CODE:0:1}
										case $C1 in
											4 )	echo Unknown Error
													;;
											5 )	echo Unknown Error
													;;
											* )	NOP=0
													;;
										esac
										;;
					esac #}}}
					;;
				
		esac
}

irc.start() {
	pid=$$
	unset IFS

	if [ -e /proc/self/fd/5 ]
	then
		exec 5<&-
	fi
	sleep 1

	exec 5<>/dev/tcp/$SERVER_ADDR/$SERVER_PORT 
	el=$?
	if [ "$el" -ne "0" ] 
	then
		echo errorlevel $el on connection attempt to "$SERVER_ADDR :$SERVER_PORT"
		exit $el
	fi

	write PASS $IRC_PASS 
	write NICK $IRC_NICK 
	write USER $HOSTNAME \* \* $HOSTNAME 
	while true
	do
		main.loop
	done
	echo "Connection Closed"
}


