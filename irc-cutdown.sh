#!/bin/bash
# http://tldp.org/LDP/abs/html/refcards.html#AEN22518	REFERENCE CARDS

if [[ $1 != "--daemonize" ]]; then
	nohup "$0" --daemonize &
	exit 0
fi

trap 'function_trap_term' TERM
trap 'function_trap' INT
BASEDIR=$(cd `dirname $0` && pwd) ; cd $BASEDIR
[ -f /etc/hostname ] && HOSTNAME=`cat /etc/hostname`
[ -z "$HOSTNAME" ] && {
	echo No hostname defined
	exit 1
}

[[ $HOSTNAME == stink ]] && { echo abort: stink breaks spanky abort; exit 1; }
. upvars.inc.sh
# . array.class.inc.sh

OURNICK="ircproxybot"
unset ADMINS; declare -a ADMINS
SERVER_ADDR=ircserver.com
SERVER_ADDR=1.2.3.4
SERVER_PORT=7776
IRC_NICK=${HOSTNAME//[^a-zA-Z0-9]/_}
IRC_PASS=password

HAVEOP=0

. daemon_watch.sh
. bandwidth.sh
. pgrep.inc.sh
. irc.inc.sh

echo "starting up" >> $0.$$.log

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
	declare -f -F $1 > /dev/null 2>&1
	return $?
}


function launch {
	local fn="/root/$1"
	test -x "$fn" && "$fn" 2>&1
	test -L $link && ! test -e $link && echo "Invalid"
}


function valid {
	local fn="/root/$1"
	test -x "$fn"
	return
}


function ips() {
	ip addr show | grep 'inet.* eth'  | sed 's/\/.*//' | sed 's/.*inet //' | sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4
}


function selfUpgrade() {
	DELAY=$1
	sleep $DELAY
	write "QUIT :Upgrading (Delayed $DELAY seconds)"
	usleep 300000
	exec ./irc.sh 
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



# BASH_VERSINFO=([0]="3" [1]="2" [2]="48" [3]="1" [4]="release" [5]="x86_64-apple-darwin10.0")
# if (( ${BASH_VERSINFO[0]} < 4 )) 
echo > /dev/udp/127.0.0.1/22 || {
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



# Wait for net
sleep_time=1
until echo > /dev/tcp/www.google.com/80 
do
	sleep $(( sleep_time += 60 ))
done

pid=$$
# while RUNNING=`netstat -anp | grep '208.109.17.....:7776.* \+ESTABLISHED.*bash' | grep -v $pid` 
# do
#  	kill -TERM `sed 's/.*ESTABLISHED //' <<<$RUNNING | sed 's/\/.*//'`
# done
unset IFS
RUNNING=( $( pgrep -f "i[r]c.sh" | grep -v $pid ) )
kill -TERM "${RUNNING[@]}" > /dev/null  2>&1

if [ -e /proc/self/fd/5 ]
then
	exec 5<&-
fi
sleep 1

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
# [ MODE ] :sfinktah!sfinktah@rox-E4FDA80C.gqle1.lon.domain.com MODE #proxies +o ec
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


on315() {
	daemon_watch | pipe_to_privmsg "#proxies" &
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


# [ JOIN ] :sfinktah!sfinktah@rox-E4FDA80C.gqle1.lon.domain.com JOIN :#proxies
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
	write "WHOIS sfinktah"
	# [ 313 ] :irc5.foonet.com 313 xc sfinktah :is a Network Administrator
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


# [ 353 ] :irc5.foonet.com 353 ec = #proxies :ec @chips7 @chips26 @chips23 @chips4 @chips5 @chips3 ...
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


on251() if :; then					# just an alternate way of surrounding a function
	write VHOST proxy wingtips
	write WATCH "+username"
	write JOIN "#channel"
	[[ $OURNICK == "ec" ]] && # [[ ${#knownBots[@]} == 0 ]] && 
		for bot in $known_bots
		do
			write WATCH "+$bot"
		done
	# write WATCH +sfinktah
fi

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
	# [ 605 ] :irc5.foonet.com 605 ec vpc_cw1zeg bash-enable-tcp.sh checklock.sh format.sh irc.sh message.txt podlock.sh smtp.sh bash-enable-tcp.sh checklock.sh format.sh irc.sh message.txt podlock.sh smtp.sh 0 :is offline
	echo \"$4\" is offline
}




declare -A knownBots=() 
declare -A missingBots=() 
declare -A presentBots=()

known_bots="chips10 chips13 chips16 chips20 chips26 chips3 chips30 chips35 chips5 chips7 chips9"
for bot in $known_bots
do
	knownBots["$bot"]="$bot"
	missingBots["$bot"]="$bot"
done

isKnownBot()
{
	[[ $OURNICK == "ec" ]] || return
	array.in_array "$1" knownBots
}


addBot()
{
	[[ $OURNICK == "ec" ]] || return
	[[ $1 == "ec" ]] && return
	echo "adding bot: $1"
	knownBots["$1"]="$1"
	presentBots["$1"]="$1"
	unset missingBots["$1"]
}


removeBot()
{
	[[ $OURNICK == "ec" ]] || return
	[[ $1 == "ec" ]] && return
	echo "removing bot: $1"
	# knownBots["$1"]="$1"
	unset presentBots["$1"]
	isKnownBot "$1" || return
	missingBots["$1"]="$1"
	declare -p presentBots
	declare -p missingBots
}


onQUIT() {
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

	[[ $OURNICK == "ec" ]] && {
		removeBot "$WHO"
		case "${MAR[1]}" in
			Ping )	
				echo $WHO just timed out | pipe_to_privmsg
				;;
			* )
				echo $WHO just quit: "$MSG" | pipe_to_privmsg
		esac
	}
}

geoip () 
{ 
    SOURCE=$(grep "^$1" /root/ips.vps | head -n1);
    echo "$1: $( curl --interface "$SOURCE" http://autoupdate.geo.opera.com/geolocation/ )" 
} 

showbots() {
	[[ $OURNICK == "ec" ]] || return
	echo "knownBots  : $( readarray -t bots < <(printf '%s\n' "${knownBots[@]}"   | sort --version-sort ); echo "${bots[@]}" )"   | pipe_to_privmsg
	echo "presentBots: $( readarray -t bots < <(printf '%s\n' "${presentBots[@]}" | sort --version-sort ); echo "${bots[@]}" )"   | pipe_to_privmsg
	echo "missingBots: ${missingBots[*]}" | pipe_to_privmsg
}


# _(Requires BASH 4)_ Reads in itself, and enumerations the **case** options.
help() {
	local lines
	local REGEX
	local commands='commands: '

	REGEX='^ +([a-z|-]+)\)'
	mapfile lines < <( declare -f onPRIVMSG )
	local len=${#lines[@]}
		local i
		for (( i=0; i<len; i++ ))
		do
			REPLY=${lines[i]}
			if [[ $REPLY =~ $REGEX ]]
			then
				commands+="${BASH_REMATCH[@]:1}"$'\n'
				# commands=${commands//|/ }
			fi
		done

		echo "$( echo "$commands" | sort -u | column -c 80 )"
}


onNOTICE() {
	# :sfinktah!sfinktah@rox-25E0BD4.gqle1.lon.domain.com NOTICE #wwii :This is a notice, you will be ponged to death.
	PREFIX="$1"
	FROM=$( split_prefix NICK "$1" )
	shift 3
	onPRIVMSG "$PREFIX" PRIVMSG "$FROM" NOITICE "$@"
}

	

onPRIVMSG() {
	# [ PRIVMSG ] :sfinktah!sfinktah@rox-E4FDA80C.gqle1.lon.domain.com PRIVMSG #proxies :hello idiot
	# [ PRIVMSG ] :sfinktah!sfinktah@rox-E4FDA80C.gqle1.lon.domain.com PRIVMSG ec :hello idiot
	# [ PRIVMSG ] :sfinktah!sfinktah@rox-E4FDA80C.gqle1.lon.domain.com PRIVMSG ec :memory
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
	if [ "${MAR[0]%,}" == "$IRC_NICK" ]; then
		CMD=${MAR[1]}
		ARG=${MAR[2]}
		ARG2=${MAR[3]}
	else
		CMD=${MAR[0]}
		ARG=${MAR[1]}
		ARG2=${MAR[2]}
	fi

	# Lowercase conversion: n=`echo $fname | tr A-Z a-z
	echo PRIVMSG: \"$MSG\"
	case "${CMD}" in
		help )
			help | pipe_to_privmsg
			;;
		bots ) 
			showbots
			;;
		free )		
			MEMTOTAL=`cat /proc/meminfo | grep MemTotal | head -n1 | sed "s/ kB//" | sed "s/.* //"`                                                                                                                                                                       
			MEMFREE=`cat /proc/meminfo | grep MemFree | head -n1 | sed "s/ kB//" | sed "s/.* //"`                                                                                                                                                                         
			INACTIVE=`cat /proc/meminfo | grep Inactive | head -n1 | sed "s/ kB//" | sed "s/.* //"`                                                                                                                                                                       
			CACHED=`cat /proc/meminfo | grep Cached | head -n1 | sed "s/ kB//" | sed "s/.* //"`                                                                                                                                                                           
			FREE=`expr $MEMFREE + $INACTIVE`                                                                                                                                                                                                                              
			printf "Free: %15s MB (MemFree: %15s Inactive: %15s)\n" "`number_format $FREE`" "`number_format $MEMFREE`" "`number_format $INACTIVE`" | pipe_to_privmsg
			;;

		active )
			ACTIVE=`cat /proc/meminfo | grep Active | head -n1 | sed "s/ kB//" | sed "s/.* //"`                                                                                                                                                                       
			echo "Active: `number_format $ACTIVE` MB" | pipe_to_privmsg
			;;

		listening )	netstat -anp | grep 'tcp\s.*0\.0\.0\.0:.*0\.0\.0\.0.*LISTEN.*/' | sed 's/0\.0\.0\.0/DEFAULT/' | sed 's/.*DEFAULT://' | sed 's/0\.0\.0\.0.\* \+LISTEN \+[0-9]\+\///' | sort -n | pipe_to_privmsg
						;;
		exit )		exit 1
						;;
		whohas )		grep "^${ARG}\$" ~/ips.vps | sed 's/..*/I have that listed in my ips.vps file/' | pipe_to_privmsg
						ips | grep "${ARG}" | pipe_to_privmsg
						[[ $HOSTNAME == "ec" ]] && grep "${ARG}" /usr/src/zillow/vps/ips.vps* | pipe_to_privmsg
						;;
		host )		host "${ARG}" | pipe_to_privmsg
						;;
		allow )		iptables -I INPUT -s "${ARG}"/32 -j ACCEPT 2>&1 | pipe_to_privmsg
						;;
		update-ips )
						(
							cd /root
							bash ifconfig-mass.sh < ips.vps 
						) | grep -v 'matched existing key' | pipe_to_privmsg
						echo done | pipe_to_privmsg
						;;
		host )		host "${ARG}" 2>&1 | head -n1 | pipe_to_privmsg
						;;

		netstat ) 	unset IFS
						active=( $( netstat -an | grep '^tcp' | awk '{ print $6 }' | sort | uniq -c | sort -n | awk '{ print $2 ":" $1 }' ) )
						echo "${active[@]}" | pipe_to_privmsg
						;;

		ips ) 		ips | column -c 132 | pipe_to_privmsg
						;;

		ipcount ) 	ips | wc -l | pipe_to_privmsg
						;;

		ifconfig )	echo `ifconfig -a | grep -c 'eth0:'` ip addresses configured | pipe_to_privmsg
						;;
		mtr )		mtr -n -r -c 10 "${ARG}" 2>&1 | tail -n 2 | sed 's/^spanky/     spanky/' | pipe_to_privmsg &
						;;
		dig )		dig +short "${ARG}" | pipe_to_privmsg &
						;;
		# ps )		ps ax -o rss=RSS,pid=PID,cmd= -C tor,divert,ssocks4,http-server | sed 's/^ \+//' | sort -rn 2>&1 | pipe_to_privmsg
		ps )		ps ax -o rss=RSS,pid=PID,cmd= | sed 's/^ \+//' | sort -rn 2>&1 | head | pipe_to_privmsg
						;;
		launch )	if [ -f /usr/src/zillow/vps/vps_process.php ]
						then
							pushd .
							cd /usr/src/zillow/vps
							if [ -z "${ARG}" ]; then
								echo missing bots: "${missingBots[@]}" | pipe_to_privmsg
								for host in ${missingBots[@]}; do
									echo attempting launch: "${host} ..." | pipe_to_privmsg
									timeout 60 vps_process --exit-on-error --host "^${host}$" --svn --irc --ssh --fast | pipe_to_privmsg
									(( ${PIPESTATUS[0]} == 2 )) && {
										echo "initial launch failed, checking for external host case" | pipe_to_privmsg
										timeout 60 vps_process --exit-on-error --external --host "^${host}$" --svn --irc --ssh --fast | pipe_to_privmsg
										if (( ${PIPESTATUS[0]} == 2 )); then
											echo "external launch failed" | pipe_to_privmsg
										fi
									}
									# main_loop
								done
								echo finished launches | pipe_to_privmsg
							else
								echo attempting launch: "${ARG} ..." | pipe_to_privmsg
								echo "vps_process --exit-on-error --host \"${ARG}\" --svn --irc --ssh --fast" | pipe_to_privmsg
								timeout 60 vps_process --exit-on-error --host "${ARG}" --svn --irc --ssh --fast | pipe_to_privmsg
								echo "pipestatus[0] was ${PIPESTATUS[0]}" | pipe_to_privmsg
								if (( ${PIPESTATUS[0]} == 2 )); then
									pgrep -f vps.php && break
									echo attempting to start virtual machine: "${host}" | pipe_to_privmsg
									php vps.php --power-on --host "${host}" &
								fi
							fi
							popd
						fi &
						;;
		upgrade )	(
						( 
							cd /root/proxies
							svn up
						) | pipe_to_privmsg
						svn --username user --password pass up /root/proxies
					) | pipe_to_privmsg
						
						selfUpgrade $(( RANDOM % 30 )) &
						;;
		renick )	write NICK $IRC_NICK 
						;;
		restart-divert )
						echo -n 'Current divert pids: '
						pidof divert | pipe_to_privmsg
						echo -n 'Current listening daemons to 9339'
						lsof -i4:9339 | pipe_to_privmsg
						pushd .
						cd /root
						pidof divert | pipe_to_privmsg
						killall -HUP divert
						sleep 1
						nohup /root/divert > /dev/null 2>&1 & 
						disown 
						popd
						sleep 1
						echo -n 'New Current listening daemons to 9339'
						echo -n 'New current divert pids: '
						pidof divert | pipe_to_privmsg
						;;
		check-pplproxy )
					check_pplproxy | pipe_to_privmsg
						;;
		check-pplnet )
					check_pplnet | pipe_to_privmsg
						;;
#						lsof -i4:59595 && echo "pplproxy listening on 59595" | pipe_to_privmsg || 
#						{ 
#							pidof pplproxy && kill -TERM $( pidof pplproxy ) | pipe_to_privmsg
#							sleep 2
#							[ -f /root/pplproxy ] && /root/pplproxy 2>&1 | pipe_to_privmsg; 
#						}
#						;;
		restart-pplproxy )
					pidof pplproxy && kill -TERM $( pidof pplproxy ) | pipe_to_privmsg
					sleep 2
					/root/pplproxy 2>&1 | pipe_to_privmsg
						;;
		restart-pplnet )
					[[ $HOSTNAME == "spanky" ]] && { echo will restarting $HOSTNAME, fuck jeff | pipe_to_privmsg ; } 
					true && {
						pidof pplnet && kill -TERM $( pidof pplnet ) | pipe_to_privmsg
						sleep 2
						check_pplnet | pipe_to_privmsg
					}
						;;
		pidof )		echo the pid of "'${ARG}':" $( pidof "${ARG}" ) | pipe_to_privmsg
						;;


		w|uptime ) 	${CMD} | grep -v USER | pipe_to_privmsg
						;;

		install )	# unset MAR[0] 
						apt-get -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' -f -q -y --force-yes install ${ARGS[@]} 2>&1 | pipe_to_privmsg
						;;
		arpflush )  ( cd /root; /root/arpflush.sh; ) | pipe_to_privmsg
					   ;;
		check )
					case "$IRC_NICK" in
						spanky )
							daemons=( divert gearproxy2 haproxy ircd lookup7d memcached myproxy node pplcontroller pplproxy socat ssocks4 Xvnc zynghole )
					esac
						;;

		threads )
			netstat -a -e -p -F -C --numeric-ports --numeric-hosts | sed 's/:::/0.0.0.0:/g' | grep '^tcp' | sed 's/\(:\|\/\|\s\+\)/\t/g' | cut -f 11,12 | sort | uniq -c | sort -rn | head | pipe_to_privmsg
			;;
		connections )
			# tcp      601      0 174.127.111.210:9339    208.99.203.245:36508    CLOSE_WAIT  24308/divert
						netstat -anp > /tmp/$$.proxies
						DivertInAll=`egrep -c ':(9339) +[0-9]' /tmp/$$.proxies`
						DivertOutAll=`egrep -c ':(9339) +[A-Z]' /tmp/$$.proxies`
						DivertOutCW=`egrep -c ':(9339) +CLOSE_WAIT' /tmp/$$.proxies`
						DivertOutTW=`egrep -c ':(9339) +TIME_WAIT' /tmp/$$.proxies`
						Socks4InAll=`egrep -c ':(9999) +[0-9]' /tmp/$$.proxies`
						rm -f /tmp/$$.proxies
						printf 'divert[%4s in, %4s out, %3s CW, %3s TW  ]  ssocks4[%3s in  ]\n' "$DivertInAll" "$DivertOutAll" "$DivertOutCW" "$DivertOutTW" "$Socks4InAll" | pipe_to_privmsg
						;;
		opera )		echo "$( curl http://autoupdate.geo.opera.com/geolocation/ )" | pipe_to_privmsg
						;;
		freegeoip ) curl -q "https://freegeoip.net/json/" | pipe_to_privmsg
						;;
		freegeoipall )
						while read -r base
						do
							echo "$base: $( curl --interface "$base" -q https://freegeoip.net/json/$base )" 
						done < /root/ips.vps | pipe_to_privmsg
						;;
							
						# for base in $( cat /root/ips.vps | cut -d . -f 1-3 | sort -u )
		operallx )
						while read -r base
						do
							echo "$base: $( curl --interface "$base" http://autoupdate.geo.opera.com/geolocation/ )" 
						done < /root/ips.vps | pipe_to_privmsg
						;;
							
						# for base in $( cat /root/ips.vps | cut -d . -f 1-3 | sort -u )

		operall )
						for base in $( cat /root/ips.vps )
						do
							echo "$base: $( curl --interface "$base" http://autoupdate.geo.opera.com/geolocation/ )" 
						done | pipe_to_privmsg
						;;

		geoip )		[ -z "$ARG" ] \
							&& IP=$( curl my.ipspace.com ) \
							|| IP="$ARG"
						
						[ -f /usr/local/bin/geoip ] \
							&&  echo geoip_result "$IP:$( geoip "$IP" )" | pipe_to_privmsg \
							|| write "PRIVMSG spanky :spanky geoip $IP" 
						;;
					issue )
						head -n1 /etc/issue | pipe_to_privmsg
						;;
		geoip_result )
						[ "$FROM" == "spanky" ] && 
						{
							FROM="#proxies"
							echo "my geoip_result was: $ARG"  | pipe_to_privmsg
						}
						;;
		bw|bandwidth )
						GET_BPS | pipe_to_privmsg
						;;
		issue )		cat /etc/issue | pipe_to_privmsg
						;;
		whois )		whois
						;;
		df )
						df -m | grep '^/dev' | pipe_to_privmsg
						;;
		md5 )
						test -n "${ARG2}" && {
							sum=$( md5sum "${ARG}" | sed 's/ .*//' )
							[[ $sum = $ARG2 ]] || md5sum "${ARG}" | pipe_to_privmsg
						} || {
							test -f "${ARG}" && md5sum "${ARG}" | pipe_to_privmsg \
								|| echo 'Invalid filename' | pipe_to_privmsg
						}
						;;
		check-* )
						app="${CMD#*-}"
						test -x /root/"$app" || return
						case "$CMD" in
							check-ssocks4 )
								CHECK_PORT=9999
								;;
							check-divert )
								CHECK_PORT=9339
								;;
						esac

						echo QUIT | nc -w 5 localhost $CHECK_PORT
						el=$?
						(( el != 0 )) && {
							echo CHECK_PORT $CHECK_PORT failed to respond | pipe_to_privmsg
							app="${CMD#*-}"
#						unset portlist
#						declare -a portlist='()'
#						while read proto recvq sendq local foreign state program; do
#							port="${local##*:}"
#							case "$port" in 
#								*[0-9]* )
#									echo $port $program
#									portlist["$port"]="$program"
#									;;
#								* )
#									echo not port: $port
#									;;
#							esac
#						done < <( netstat -tnlp )
#						test -z "${portlist[$CHECK_PORT]}" && test -x "/root/$app" && 
#						{
							# test -e /home/sfinktah/wrangler/addcomment && /home/sfinktah/wrangler/addcomment "irc.sh: restarted $app"
							killall -HUP $app
							echo launching $app | pipe_to_privmsg
							nohup /root/$app > /dev/null 2>&1 &
							lsof -i4:$CHECK_PORT | pipe_to_privmsg
							disown
						}
						;;
		lsof )
						# http://tldp.org/LDP/abs/html/string-manipulation.html
						# http://ss64.com/bash/printf.html
						# ps ax -o pid=,rss=,cmd= | sed 's/^ \+//' | sed 's/  \+/ /' > tmp.ps.$$
						DAEMONS=`netstat -anp | tee tmp.$$ | grep 'tcp .*0\.0\.0\.0:.*0\.0\.0\.0.*LISTEN.*/' | sed 's/0\.0\.0\.0/DEFAULT/' | sed 's/.*DEFAULT://' | sed 's/.* \+LISTEN \+//' | sort -un`
						unset IFS
						# cat \ # <( printf "%4s %4s %7s %-20s %6s %5s%% %5s %s\n" CONS LSOF RSS DAEMON START CPU PID CMDLINE ) \
						# <( 
							for DAEMON in $DAEMONS
							do
								COUNT=`grep -c "$DAEMON" tmp.$$`
								PID=`expr "$DAEMON" : '\([0-9]\+\)'`
								RSS=`ps -p $PID -o rss=`
								CMD=`ps -p $PID -o cmd=`
								START=`ps -p $PID -o start_time=`
								PCPU=`ps -p $PID -o pcpu=`
								CONNECTIONS=`lsof -p ${PID} | grep IPv4 | wc -l`
								DAEMON=`expr "$DAEMON" : '.*/\(.*\)'`
								MEM=`number_format $RSS`
								if [ "$DAEMON" == "divert" ] 
								then
									if (( CONNECTIONS==1 ))
									then
										echo killing $DAEMON $PID for having 1 connection
										kill -TERM $PID 2>&1
									fi
								fi
								# printf "%4s %4s %7s %-20s %6s %5s%% %5s %s\n" $COUNT $CONNECTIONS $MEM $DAEMON $START $PCPU $PID "$CMD"
							done | pipe_to_privmsg
						# ) | pipe_to_privmsg
						rm tmp.$$
						# rm tmp.ps.$$

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
	printf "errorlevel: %2s  lenreply: %3s\n" $el "${#REPLY}"
	if [ "$el" -ne "0" ]
	then
		echo "Connection EOF/timeout Errorlevel $el" >> $0.$$.log
		sleep 60
		exec "$0" "$@" || 
		echo "exec failed" >> $0.$$.log
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
		ERROR )	# [ :Closing ] ERROR :Closing Link: sup_er_fragi[CPE-1-1-251-137.gqle1.lon.domain.com] (Ping timeout)
			# ERROR :Closing Link: c32[206.217.196.44] (Ping timeout)
					echo "$REPLY" >> $0.$$.log 
					sleep 5
					exec "$0" "$@"
					;;
		* ) 		function_exists "on$CODE" && "on$CODE" "${RARRAY[@]}" || \
					case $CODE in #{{{
						251 )			write JOIN "#proxies"
										;;
						433 )			write NICK ${IRC_NICK}_$$
										;;
						NOTICE )		;;
						JOIN )		;;
						PRIVMSG )	
										# Unknown IRC code PRIVMSG
										# [ PRIVMSG ] :sfinktah!sfinktah@rox-E4FDA80C.gqle1.lon.domain.com PRIVMSG #proxies :hello idiot
										# [ PRIVMSG ] :sfinktah!sfinktah@rox-E4FDA80C.gqle1.lon.domain.com PRIVMSG ec :hello idiot
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


write PASS $IRC_PASS 
write NICK $IRC_NICK 
write USER $HOSTNAME \* \* $HOSTNAME 
while true
do
	main.loop
done > irc.sh-log 2>&1
