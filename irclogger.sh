#!/bin/bash
# http://tldp.org/LDP/abs/html/refcards.html#AEN22518	REFERENCE CARDS
trap 'function_trap_term' TERM
trap 'function_trap' INT
BASEDIR=$(cd `dirname $0` && pwd) ; cd $BASEDIR
[ -f /etc/hostname ] && HOSTNAME=`cat /etc/hostname`
[ -z "$HOSTNAME" ] && {
	echo No hostname defined
	exit 1
}
OURNICK="logbot"
HAVEOP=0

# . date.sh
. daemon_watch.sh
. bandwidth.sh
# . rfc1459.inc.sh
. pgrep.inc.sh
. irc.inc.sh


echo "starting up" >> $0.$$.log

function_trap_term() {
	write "QUIT :SIGTERM (Are we rebooting?)"
	exit 13
}

function_trap() {
	echo "^C (SIGINT) detected..."

	write "QUIT :^C (SIGINT)"
	exit 13


}

function_exists() {
	declare -f -F $1 > /dev/null
	return $?
}


echo > /dev/tcp/www.google.com/80  || {
	echo You version of BASH is not compiled with net redirection
	cat /etc/issue
	# Debian GNU/Linux 5.0 \n \l
	grep "Debian.*Linux 5" /etc/issue && {
		grep "mirror.nt4.com" /etc/apt/sources.list || {
			sed -e '1ideb http://mirror.nt4.com/debian/ proxy-testing/' /etc/apt/sources.list > tmp.$$
			cp tmp.$$ /etc/apt/sources.list
			rm tmp.$$
			apt-get update
		}
		apt-get install --force-yes -y bash/proxy-testing && exec $0 $@
	}
	exit 1
}

pid=$$
# while RUNNING=`netstat -anp | grep '208.109.17.....:7776.* \+ESTABLISHED.*bash' | grep -v $pid` 
# do
#  	kill -TERM `sed 's/.*ESTABLISHED //' <<<$RUNNING | sed 's/\/.*//'`
# done
unset IFS
RUNNING=( $( pgrep -f "i[r]c.sh" | grep -v $pid ) )
kill -TERM "${RUNNING[@]}" > /dev/null  2>&1


SERVER_ADDR=chips5.nt4.com
SERVER_PORT=7776
IRC_NICK=${HOSTNAME//[^a-zA-Z0-9]/_}
IRC_PASS=fuckzynga
exec 5<>/dev/tcp/$SERVER_ADDR/$SERVER_PORT 
el=$?
if [ "$el" -ne "0" ] 
then
	sleep 60 
	exec "$0" "$@"
fi

write() {
	echo ">>> " "$@"
	echo "$@" >&5
}


away() {
	if [ -z "$1" ]
	then
		write "AWAY"
	else
		write "AWAY" ":$@"
	fi
}

# [ 332 ] :irc5.foonet.com 332 ec ${LOG_CHANNEL} :BashMan's Lair
on332() {
	OURNICK="$3"
	# [ -n "$INTERVAL" ] && printf 'Was offline for %s' "$INTERVAL" | pipe_to_privmsg
}

# Ops
# [ MODE ] :cyrus!cyrus@rox-E4FDA80C.gqle1.lon.bigpond.net.au MODE ${LOG_CHANNEL} +o ec
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



# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} chips25 proxy irc5.foonet.com chips25 H@ :0 chips25
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} c14 proxy irc5.foonet.com c14 H@ :0 c14
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} Pod B00D6373.D2380C72.C7E358E6.IP irc6.foonet.com Pod H :1 Pod
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} win1 proxy irc5.foonet.com win1 H :0 win1
# [ 315 ] :irc5.foonet.com 315 ec ${LOG_CHANNEL} :End of /WHO list.
on315() {
	daemon_watch | pipe_to_privmsg "${LOG_CHANNEL}" &
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
		write "MODE $CHANNEL +o $NAME"
	fi
}

# [ JOIN ] :cyrus!cyrus@rox-E4FDA80C.gqle1.lon.bigpond.net.au JOIN :${LOG_CHANNEL}
onJOIN() {

	FROM_ADDR="$( split_prefix ADDR "$1" )"
	FROM_NICK="$( split_prefix NICK "$1" )"

	CHANNEL=$( strip_colon "$3" )
	if [ "$HAVEOP" -eq "1" -a "$FROM_ADDR" == "proxy" ]
	then
		write "MODE $CHANNEL +o $FROM_NICK"
	fi
}

# [ 353 ] :irc5.foonet.com 353 ec = ${LOG_CHANNEL} :ec @chips7 @chips26 @chips23 @chips4 @chips5 @chips3 @centos8 servant tank ...
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
		else
			# Private Message
			USER=${1}
		fi

		echo Noticed user $USER
		(( BOTS_B4_ME ++ ))
	done
}

# [ 366 ] :irc5.foonet.com 366 ec ${LOG_CHANNEL} :End of /NAMES list.
on366() {
	CHANNEL=$4
	# write "WHO $4"
}

on251() if :; then					# just an alternate way of surrounding a function
	write VHOST proxy wingtips
	write WATCH "+vpc_cw1zeg"
	write JOIN "${LOG_CHANNEL}"
	# write WATCH +cyrus
fi

on600() {
	echo $3 has logged on
}

on601() {
	echo $3 has logged off
}

on604() {
	echo $3 already online
}

on605() {
	# :irc5.foonet.com 605 ec vpc_cw1zeg * * 0 :is offline
	# [ 605 ] :irc5.foonet.com 605 ec vpc_cw1zeg bash-enable-tcp.sh checklock.sh format.sh irc.sh message.txt podlock.sh smtp.sh bash-enable-tcp.sh checklock.sh format.sh irc.sh message.txt podlock.sh smtp.sh 0 :is offline
	echo \"$4\" is offline
}

onQUIT() {
	local FROM=$( split_prefix NICK "$1" )

	shift 2
	MSG="$@"
	MSG=$( strip_colon "${MSG:1}" )
	declare -a MAR
	MAR=( $MSG )
	# Lowercase conversion: n=`echo $fname | tr A-Z a-z
	echo PRIVMSG: \"$MSG\"
	case "${MAR[0]}" in
		Ping )	echo $FROM just timed out | pipe_to_privmsg
					;;
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
	# [ PRIVMSG ] :cyrus!cyrus@rox-E4FDA80C.gqle1.lon.bigpond.net.au PRIVMSG ${LOG_CHANNEL} :hello idiot
	# [ PRIVMSG ] :cyrus!cyrus@rox-E4FDA80C.gqle1.lon.bigpond.net.au PRIVMSG ec :hello idiot
	# [ PRIVMSG ] :cyrus!cyrus@rox-E4FDA80C.gqle1.lon.bigpond.net.au PRIVMSG ec :memory
	# PRIVMSG: "memory"

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
	if [ "${MAR[0]}" == "$IRC_NICK" ]; then
		CMD=${MAR[1]}
		ARG=${MAR[2]}
	else
		CMD=${MAR[0]}
		ARG=${MAR[1]}
	fi

	# Lowercase conversion: n=`echo $fname | tr A-Z a-z
	echo PRIVMSG: \"$MSG\"
	case "${CMD}" in
		* ) echo "$MSG" >> $0.$$.log
			;;
	esac
}


# if [ -n "$IRC_LAST_PACKET" ]
# then
# 	NOW=$(now)
# 	INTERVAL=$(elapsed "$IRC_LAST_PACKET" "$NOW")
# fi


write PASS $IRC_PASS 
write NICK $IRC_NICK 
write USER $HOSTNAME \* \* $HOSTNAME 
while true
do
	# export 
	read -t 300 -r REPLY <&5
	el=$?
	if [ "$el" -ne "0" ]
	then
		echo "Connection EOF/timeout Errorlevel $el" >> $0.$$.log
		sleep 60
		exec "$0" "$@"
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
	echo [ "$CODE" ] "$REPLY"

	case $PREFIX in
		PING )	unset RARRAY[0]
					write PONG "${RARRAY[@]}"
					;;
		ERROR )	# [ :Closing ] ERROR :Closing Link: sup_er_fragi[CPE-124-190-251-137.gqle1.lon.bigpond.net.au] (Ping timeout)
 			# ERROR :Closing Link: c32[206.217.196.44] (Ping timeout)
					echo "$REPLY" >> $0.$$.log 
					sleep 5
					exec "$0" "$@"
					;;
		* ) 		function_exists on$CODE && on$CODE ${RARRAY[@]} || \
					case $CODE in #{{{
						251 )			write JOIN "${LOG_CHANNEL}"
										;;
						433 )			write NICK ${IRC_NICK}_$$
										;;
						NOTICE )		;;
						JOIN )		;;
						PRIVMSG )	
										# Unknown IRC code PRIVMSG
										# [ PRIVMSG ] :cyrus!cyrus@rox-E4FDA80C.gqle1.lon.bigpond.net.au PRIVMSG ${LOG_CHANNEL} :hello idiot
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


										on_privmsg ${RARRAY[@]}
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
done
echo "Connection Closed" >> $0.log
sleep 60
exec "$0" "$@"


# ERROR :Closing Link: c32[206.217.196.44] (Ping timeout)

# :Chad3420!chips6_342@rox-9A2076D7 QUIT :Quit: __destruct(wzap maxTime during NullRead while not seated - OP10 R127)
# [ JOIN ] :cyrus!cyrus@rox-E4FDA80C.gqle1.lon.bigpond.net.au JOIN :${LOG_CHANNEL}
# Unknown IRC code JOIN
# [ PRIVMSG ] :cyrus!cyrus@rox-E4FDA80C.gqle1.lon.bigpond.net.au PRIVMSG ${LOG_CHANNEL} :hello idiot
# Unknown IRC code PRIVMSG
# [ PRIVMSG ] :cyrus!cyrus@rox-E4FDA80C.gqle1.lon.bigpond.net.au PRIVMSG ec :hello idiot
# Unknown IRC code PRIVMSG

# :irc18.foonet.com 001 ten :Welcome to the ROXnet IRC Network ten!ten@localhost
# :irc18.foonet.com 002 ten :Your host is irc18.foonet.com, running version Unreal3.2.8.1
# :irc18.foonet.com 003 ten :This server was created Sat Jul 16 2011 at 19:26:54 PDT
# :irc18.foonet.com 004 ten irc18.foonet.com Unreal3.2.8.1 iowghraAsORTVSxNCWqBzvdHtGp lvhopsmntikrRcaqOALQbSeIKVfMCuzNTGj
# :irc18.foonet.com 005 ten UHNAMES NAMESX SAFELIST HCN MAXCHANNELS=100 CHANLIMIT=#:100 MAXLIST=b:60,e:60,I:60 NICKLEN=30 CHANNELLEN=32 TOPICLEN=307 KICKLEN=307 AWAYLEN=307 MAXTARGETS=20 :are supported by this server
# :irc18.foonet.com 005 ten WALLCHOPS WATCH=128 WATCHOPTS=A SILENCE=15 MODES=12 CHANTYPES=# PREFIX=(qaohv)~&@%+ CHANMODES=beI,kfL,lj,psmntirRcOAQKVCuzNSMTG NETWORK=ROXnet CASEMAPPING=ascii EXTBAN=~,cqnr ELIST=MNUCT STATUSRARRAY=~&@%+ :are supported by this server
# :irc18.foonet.com 005 ten EXCEPTS INVEX CMDS=KNOCK,MAP,DCCALLOW,USERIP :are supported by this server
# :irc18.foonet.com 251 ten :There are 1 users and 2050 invisible on 4 servers
# :irc18.foonet.com 252 ten 1 :operator(s) online
# :irc18.foonet.com 254 ten 4080 :channels formed
# :irc18.foonet.com 255 ten :I have 1514 clients and 1 servers
# :irc18.foonet.com 265 ten :Current Local Users: 1514  Max: 2000
# :irc18.foonet.com 266 ten :Current Global Users: 2051  Max: 3587
# :irc18.foonet.com 422 ten :MOTD File is missing
# :ten MODE ten :+iwx
# JOIN #location
# :ten!ten@rox-9A2076D7 JOIN :#location
# :irc18.foonet.com 353 ten = #location :@ten 
# :irc18.foonet.com 366 ten #location :End of /NAMES list.
# 


# [ MODE ] :ec MODE ec :+iwx
# [ JOIN ] :ec!ec@rox-E4FDA80C.gqle1.lon.bigpond.net.au JOIN :${LOG_CHANNEL}
# [ 353 ] :irc5.foonet.com 353 ec = ${LOG_CHANNEL} :ec chips13 c14 chips10 chips35 mailer_daemon chips30 chips19 c12 c34 win1 chips28 vpn chips7 c32 chips26 c31 chips25 chips27
# [ 366 ] :irc5.foonet.com 366 ec ${LOG_CHANNEL} :End of /NAMES list.
# [ JOIN ] :cyrus!cyrus@rox-E4FDA80C.gqle1.lon.bigpond.net.au JOIN :${LOG_CHANNEL}
# [ MODE ] :cyrus!cyrus@rox-E4FDA80C.gqle1.lon.bigpond.net.au MODE ${LOG_CHANNEL} +o cyrus

# 
# listening on en0, link-type EN10MB (Ethernet), capture size 65535 bytes
# WATCH +ec
# :irc5.foonet.com 604 cyrus ec ec rox-E4FDA80C.gqle1.lon.bigpond.net.au 1330930800 :is online
# (605 is off)
#
# [ 600 ] :irc5.foonet.com 600 ec cyrus cyrus rox-E4FDA80C.gqle1.lon.bigpond.net.au 1330931352 :logged online
# [ 601 ] :irc5.foonet.com 601 ec cyrus cyrus rox-E4FDA80C.gqle1.lon.bigpond.net.au 1330931336 :logged offline

# WHOIS ec ec
# :irc5.foonet.com 311 cyrus ec ec rox-E4FDA80C.gqle1.lon.bigpond.net.au * :ec
# :irc5.foonet.com 379 cyrus ec :is using modes +iwx 
# :irc5.foonet.com 378 cyrus ec :is connecting from *@CPE-124-190-251-137.gqle1.lon.bigpond.net.au 124.190.251.137
# :irc5.foonet.com 312 cyrus ec irc5.foonet.com :FooNet Server
# :irc5.foonet.com 317 cyrus ec 139 1330930800 :seconds idle, signon time
# :irc5.foonet.com 318 cyrus ec :End of /WHOIS list.

# Ops
# [ MODE ] :cyrus!cyrus@rox-E4FDA80C.gqle1.lon.bigpond.net.au MODE ${LOG_CHANNEL} +o ec


# We join
# [ JOIN ] :ec!ec@proxy JOIN :${LOG_CHANNEL}
# [ 332 ] :irc5.foonet.com 332 ec ${LOG_CHANNEL} :BashMan's Lair
# [ 333 ] :irc5.foonet.com 333 ec ${LOG_CHANNEL} cyrus 1332688928
# [ 353 ] :irc5.foonet.com 353 ec = ${LOG_CHANNEL} :ec @chips7 @chips26 @chips23 @chips4 @chips5 @chips3 @centos8 servant tank @chips16 @chips13 @chips10 @chips35 @chips30 @chips19 @chips20 @chips9 xs @c17 @chips28 @c12 mailer_daemon_co @chips2 @c32 win1 vpn @c30 @c34 @c31 @chips27 @chips25 @c14 @cyrus Pod 
# [ 366 ] :irc5.foonet.com 366 ec ${LOG_CHANNEL} :End of /NAMES list.
# Someone leaves
# [ PART ] :cyrus!cyrus@rox-E4FDA80C.gqle1.lon.bigpond.net.au PART ${LOG_CHANNEL} :Leaving
# Someone joins
# [ JOIN ] :cyrus!cyrus@rox-E4FDA80C.gqle1.lon.bigpond.net.au JOIN :${LOG_CHANNEL}

# WHO ${LOG_CHANNEL}
# WHO ${LOG_CHANNEL}
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} ec proxy irc5.foonet.com ec H :0 ec
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} cyrus rox-E4FDA80C.gqle1.lon.bigpond.net.au irc5.foonet.com cyrus H* :0 Cyrus
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} chips7 proxy irc5.foonet.com chips7 H@ :0 chips7
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} chips26 proxy irc5.foonet.com chips26 H@ :0 chips26
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} chips23 proxy irc5.foonet.com chips23 H@ :0 chips23
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} chips4 proxy irc5.foonet.com chips4 H@ :0 chips4
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} chips5 proxy irc5.foonet.com chips5 H@ :0 chips5
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} chips3 proxy irc5.foonet.com chips3 H@ :0 chips3
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} centos8 proxy irc5.foonet.com centos8 H@ :0 centos8
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} servant proxy irc5.foonet.com servant H :0 servant
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} tank proxy irc5.foonet.com tank H :0 tank
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} chips16 proxy irc5.foonet.com chips16 H@ :0 chips16
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} chips13 proxy irc5.foonet.com chips13 H@ :0 chips13
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} chips10 proxy irc5.foonet.com chips10 H@ :0 chips10
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} chips35 proxy irc5.foonet.com chips35 H@ :0 chips35
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} chips30 proxy irc5.foonet.com chips30 H@ :0 chips30
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} chips19 proxy irc5.foonet.com chips19 H@ :0 chips19
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} chips20 proxy irc5.foonet.com chips20 H@ :0 chips20
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} chips9 proxy irc5.foonet.com chips9 H@ :0 chips9
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} xs proxy irc5.foonet.com xs H :0 xs
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} c17 proxy irc5.foonet.com c17 H@ :0 c17
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} chips28 proxy irc5.foonet.com chips28 H@ :0 chips28
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} c12 proxy irc5.foonet.com c12 H@ :0 c12
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} mailer-dae proxy irc5.foonet.com mailer_daemon_co H :0 mailer-daemon.co
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} chips2 proxy irc5.foonet.com chips2 H@ :0 chips2
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} c32 proxy irc5.foonet.com c32 H@ :0 c32
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} win1 proxy irc5.foonet.com win1 H :0 win1
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} vpn proxy irc5.foonet.com vpn H :0 vpn
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} c30 proxy irc5.foonet.com c30 H@ :0 c30
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} c34 proxy irc5.foonet.com c34 H@ :0 c34
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} c31 proxy irc5.foonet.com c31 H@ :0 c31
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} chips27 proxy irc5.foonet.com chips27 H@ :0 chips27
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} chips25 proxy irc5.foonet.com chips25 H@ :0 chips25
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} c14 proxy irc5.foonet.com c14 H@ :0 c14
# [ 352 ] :irc5.foonet.com 352 ec ${LOG_CHANNEL} Pod B00D6373.D2380C72.C7E358E6.IP irc6.foonet.com Pod H :1 Pod
# [ 315 ] :irc5.foonet.com 315 ec ${LOG_CHANNEL} :End of /WHO list.

# netstat -anp | tee tmp.$$ | sed 's/:::/0.0.0.0:/' | grep 'tcp .*0\.0\.0\.0:.*0\.0\.0\.0.*LISTEN.*/' | sed 's/0\.0\.0\.0/DEFAULT/' | sed 's/.*DEFAULT://' | sed 's/.* \+LISTEN \+//' | sort -un
# | sed 's/0\.0\.0\.0/DEFAULT/' | sed 's/.*DEFAULT://' | sed 's/.* \+LISTEN \+//' | sort -un
# netstat -anp | grep 'tcp .*0\.0\.0\.0:.*0\.0\.0\.0.*LISTEN.*/' 
# netstat -anp | sed 's/:::/0.0.0.0:/' | grep 'tcp .*0\.0\.0\.0:.*0\.0\.0\.0.*LISTEN.*/' | sed 's/0\.0\.0\.0/DEFAULT/' 
# | sed 's/.*DEFAULT://' | sed 's/.* \+LISTEN \+//' | sort -un
# | cut -f 5 | sort -un | xargs -ixx echo "-A INPUT --dport xx -j ACCEPT"
# netstat -anp | sed 's/:::/0.0.0.0:/g' | egrep -o '^(udp|tcp).*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):([0-9]+)\s+0.0.0.0:\*.*LISTEN.*' | grep -v '127\.0\.0\.1' | sed 's/\(:\|\s\+\)/\t/g' 
# 
# netstat -e -o -p -l -F -C -W -n
# netstat -e -p -l -F -C -W --numeric-ports --numeric-hosts \
# 	sed 's/:::/0.0.0.0:/g' \
# 	egrep -o '^(udp|tcp).*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):([0-9]+)\s+0.0.0.0:\*.*LISTEN.*'
# netstat -e -p -l -F -C -W --numeric-ports --numeric-hosts | sed 's/:::/0.0.0.0:/g' | egrep '^(udp|tcp).*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+):([0-9]+)\s+0.0.0.0:\*.*LISTEN.*'
# 
# 
# #!/bin/bash
# COLUMN_NAMES=( proto recvq sendq local address foreign address state user inode pid program )
# netstat -e -p -l -F -C -W --numeric-ports --numeric-hosts | sed 's/:::/0.0.0.0:/g' | grep -v '127\.0\.0\.1' | grep -v "::" | grep '^tcp' | sed 's/\(:\|\/\|\s\+\)/\t/g' | while IFS= read -r LINE
# do
#    echo "$LINE"
#    num=0
#    for name in $COLUMN_NAMES
#    do
#       record[$name]=${field[$num]}
#       echo record $name = "${field[$num]}"
#       (( num++ ))
#    done
# done
# 
# # Proto	Recv-Q	Send-Q	Local	Address	Foreign	Address	State	User	Inode	PID	Program
# # tcp	0	0	0.0.0.0	111	0.0.0.0	*	LISTEN	root	4711	1675	portmap	
# # tcp	0	0	0.0.0.0	52242	0.0.0.0	*	LISTEN	root	6340	-	
# # tcp	0	0	0.0.0.0	45140	0.0.0.0	*	LISTEN	root	6421	2774	rpc.mountd	
# # tcp	0	0	0.0.0.0	21	0.0.0.0	*	LISTEN	root	6969	2877	vsftpd	
# # tcp	0	0	0.0.0.0	53	0.0.0.0	*	LISTEN	root	5098	1888	dnsmasq	
# # tcp	0	0	0.0.0.0	22	0.0.0.0	*	LISTEN	root	5125	1900	sshd	
# # tcp	0	0	0.0.0.0	1080	0.0.0.0	*	LISTEN	root	7528	3154	ssocks4	
# # tcp	0	0	0.0.0.0	4730	0.0.0.0	*	LISTEN	root	151245	10880	gearmand	
# # tcp	0	0	0.0.0.0	2049	0.0.0.0	*	LISTEN	root	6320	-	
# # tcp	0	0	192.168.1.5	9100	0.0.0.0	*	LISTEN	root	6725	2865	tor	
# # tcp	0	0	0.0.0.0	56364	0.0.0.0	*	LISTEN	statd	4763	1694	rpc.statd	
# # tcp6	0	0	0.0.0.0	80	0.0.0.0	*	LISTEN	root	7461	3118	apache2	
# # tcp6	0	0	0.0.0.0	113	0.0.0.0	*	LISTEN	root	6867	2928	xinetd	
# # tcp6	0	0	0.0.0.0	53	0.0.0.0	*	LISTEN	root	5100	1888	dnsmasq	
# # tcp6	0	0	0.0.0.0	22	0.0.0.0	*	LISTEN	root	5127	1900	sshd	
# # tcp6	0	0	0.0.0.0	25	0.0.0.0	*	LISTEN	root	6866	2928	xinetd	
# # tcp6	0	0	0.0.0.0	1241	0.0.0.0	*	LISTEN	root	6865	2928	xinetd	
# # tcp6	0	0	0.0.0.0	4730	0.0.0.0	*	LISTEN	root	151246	10880	gearmand	
# # tcp6	0	0	0.0.0.0	443	0.0.0.0	*	LISTEN	root	7465	3118	apache2	
# # tcp6	0	0	0.0.0.0	445	0.0.0.0	*	LISTEN	root	7300	2800	smbd	
# # tcp6	0	0	0.0.0.0	139	0.0.0.0	*	LISTEN	root	7302	2800	smbd	
