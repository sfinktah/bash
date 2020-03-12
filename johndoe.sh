#!/bin/bash
# screen -X title "johndoe tty ${GPG_TTY##*/}"
printf "\033k%s\033\\" "tty ${GPG_TTY##*/}"
BASEDIR=$(cd `dirname $0` && pwd) ; cd $BASEDIR
. include mysql

. $BASEDIR/json.sh
. $BASEDIR/raw_gearman.sh

# Configuration # {{{
QUEUE=YahooRefresh		# A queue of JSON objects describing new accounts
QUEUE=YahooPodReady		# or a quoted username only.
# SKIP_S_COOKIES=1			# Skip cookies which we already have full "remember me" s, and  xs cookies for.
# FB_NOPIC_ONLY=

QUEUE=YahooReadyPodTest
QUEUE=YahooRefreshFacebookLoginFailed

popshift="shift"
# (( $$ % 2 )) && popshift="shift"

# QUEUE=refresh_cookie
# FB_REFRESH=0
# QUEUE=redo
# QUEUE=YahooReadyPod
# FB_REFRESH=1
# QUEUE="add_app"
# [ -f .swap ] && {
# 	QUEUE=YahooReadyCutoff
# 	ADD_APP=1
# 	rm .swap
# } || touch .swap # }}}

ready=0
used=0
# ready=$( wget -q -O - 'http://marrison.com/wwiiajax.php' | grep -c RDY )
# used=$( wget -q -O - 'http://marrison.com/wwiiajax.php' | grep -c OKUSED )
# echo "$ready READY   $used USED" >&2
unset QUEUES
declare -a QUEUES
if (( ready > 8 && used < 8 && !( $$ % (64 - ready) ) )); then
# if (( ready > 4 && used < 8 )); then
	QUEUES+=(YahooReadyCutoff)
	QUEUES+=(YahooReadyDoubleConfirm)
	ADD_APP=
else
	QUEUES+=(YahooReadyCurrent2)
	QUEUES+=(YahooReadyCurrent)
	QUEUES+=(YahooReadyDoubleConfirm)
	# if (( $$ % 2 )); then
	QUEUES+=(YahooReadyPic)
	QUEUES+=(YahooReadyRefresh)
	QUEUES+=(YahooReadyPod)
	# QUEUES=( $( echo "${QUEUES[@]}" | xargs -n1 echo | sort -R ) )
	ADD_APP=1
fi

# declare -p QUEUES >&2 # {{{
# QUEUE=YahooReadyPod # {{{
# ADD_APP=1
# QUEUE=YahooNotBroken
# QUEUE=YahooReady2

# QUEUE=YahooRefreshFacebookLoginFailed ADD_APP=0
# QUEUE=YahooRefreshDead
# NO_ADD_PIC=1
# QUEUE=YahooReadyPod
# ADD_APP=0

# End Configuration

# STACKCLIENT="php /usr/src/wrangler/trunk/common/StackClient.php" # }}}#}}}

# Desired settings 
(
IP=
FIRST=
LAST=
EMAIL=
PASS=
DAY=
MONTH=
YEAR=
GENDER=
)

# $1 - username
populate_useragent() # {{{
{
	# Some default that will most likely never be used
	TZ="Europe/Berlin"
	HEIGHT="961"
	WIDTH="1920"
	UAGENT="Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/535.19 (KHTML, LIKE Gecko) Chrome/18.0.1025.162 Safari/535.19"

	SQL=" "
	SQL+=" SELECT window_innerWidth    AS WIDTH"
	SQL+=" , window_innerHeight AS HEIGHT"
	SQL+=" , useragent          AS UAGENT"
	SQL+=" FROM   (SELECT *"
	SQL+=" FROM   (SELECT COUNT(*) AS c"
	SQL+=" , browser_fingerprint"
	SQL+=" , screen_width_height"
	SQL+=" , window_innerWidth"
	SQL+=" , window_innerHeight"
	SQL+=" , useragent"
	SQL+=" FROM   browsers"
	SQL+=" GROUP  BY screen_width_height"
	SQL+=" , browser_fingerprint) AS ss1"
	SQL+=" WHERE  (useragent LIKE '%AppleWebKit%'"
	SQL+=" OR   useragent LIKE '%Gecko%')"
	SQL+=" AND ( useragent LIKE '%Macintosh%'"
	SQL+=" OR useragent LIKE '%Windows%' )"
	# SQL+="            AND window_innerWidth < 1400"
	SQL+=" AND c > 20"
	SQL+=" ORDER  BY c DESC) AS ss2"
	SQL+=" ORDER  BY RAND()"
	SQL+=" LIMIT  1"

	# echo SQL: "$SQL" # {{{
	# SQLRESULT="$( echo "${SQL}" | nc -q 10 localhost 3307 | sed 's/":"/="/g' | sed 's/","/" /g' | sed 's/^...//' | sed 's/..$//' )"
	# SQLRESULT="${SQLRESULT//\\}" # }}}

	mysql.server /dev/tcp/localhost/3307

	# mysql.describe accounts # {{{
	# array.new user

	# user[proxy]=127.0.0.1
	# user[username]=fred1@test.com
	# user[firstname]=Fred
	# user[lastname]=Flintstone
	# user[password]=87vette
	# 
	# user.foreach
	# do
	# 	printf "%10s %s\n" $key "${user[$key]}"
	# done
	# 
	# mysql.setvars user
	# mysql.connect
	# mysql.query "INSERT INTO mega SET $SETVARS"
	# dd <&$MYSQLFD 2>/dev/null # }}}

	mysql.select "$SQL"
	if mysql.result 
	then

		mysql.printrow ROW >&2
		for c in "${!ROW[@]}"
		do
			echo "$c=${ROW[$c]}" >&2
			eval "$c=\${ROW[$c]}" 
		done
		return 0
	else
		echo "No result returned from MySQL: $SQL" >&2
		return 1
	fi

} # }}}

# $1 username
populate_yahoo_new_accounts()
{
	local username="$1"
	mysql.server /dev/tcp/localhost/3307

		echo checking accounts for facebook password and updated proxy >&2
		SQL="SELECT password as FB_PASS, ip_address as OVER_IP from accounts where username='$username' LIMIT 1"
		echo $SQL >&2
		mysql.select "$SQL"
		if mysql.result 
		then
			echo found facebook password >&2
			mysql.printrow ROW >&2
			for c in "${!ROW[@]}"
			do
				echo "$c=${ROW[$c]}" >&2
				eval "$c=\${ROW[$c]}"
			done
		else
			echo found nothing >&2
		fi
	# firstname	gender	id	lastname	password	day	month	year	zip	sq1	sq2	username	altemail	pic	proxy	city	q1	q2	dob	email


	SQL="select firstname as FIRST, lastname as LAST, username AS EMAIL, proxy AS IP, password AS PASS, day as DAY, month as MONTH, concat('19', year) as YEAR, gender as GENDER from yahoo_new_accounts where username = '$username' LIMIT 1"
	mysql.select "$SQL"
	if mysql.result 
	then
		mysql.printrow ROW >&2
		for c in "${!ROW[@]}"
		do
			echo "$c=${ROW[$c]}" >&2
			eval "$c=\${ROW[$c]}"
		done



		echo checking yahoo_changed_accounts for new password >&2
		SQL="SELECT password as YAHOO_PASS FROM yahoo_changed_accounts WHERE username='$username' LIMIT 1"
		echo $SQL >&2
		mysql.select "$SQL"
		if mysql.result 
		then
			echo found changed password >&2
			mysql.printrow ROW >&2
			for c in "${!ROW[@]}"
			do
				echo "$c=${ROW[$c]}" >&2
				eval "$c=\${ROW[$c]}"
			done
		else
			echo found nothing >&2
		fi




		return 0
	else
		echo "No result returned from MySQL: $SQL" >&2
		return 1
	fi
}

populate_cookies()
{
	source <( wget -q -O - http://c.facebook.com/cookies/clone.php?username=$1 | grep '## BASH_DECLARE' )
}

array.show()
{
	get_array_by_ref
	array.reset E
	array.each E
	for key in "${!E[@]}"
	do
		echo -e "$key\t${E[$key]}"
	done | column -s $'\t' -t
	echo
}
# unset SQL_REPLY COOKIE_LIST
dequeue()
{
	local -A SQL_REPLY
	local -A COOKIE_LIST
	repeat=1
	while (( repeat ))
	do
		[ -f .abort -o -f .restart ] && {
			echo abort or break set >&2
			break
		}
		echo "<" >&2
		secure=0
		repeat=0
		REPLY=
		OVER_IP= IP= FIRST= LAST= EMAIL= PASS= DAY= MONTH= YEAR= GENDER= USERNAME= NO_ADD_PIC= FB_REFRESH= FB_NEW_ACCOUNT=
		COOKIE_LIST=() SQL_REPLY=() 
		
		array_shift QUEUE QUEUES
		echo "Queue: $QUEUE" >& 2

		open /dev/tcp/192.168.46.15/4730 rw || throw "Couldn't open connection to gearman server"
		raw_gearman_packet --req --command SUBMIT_JOB --function Stack --data '{"operation":"'$popshift'","stackname":"'"$QUEUE"'"}' >&$FD	|| throw "Couldn't write to gearman socket"
		raw_gearman_get_result $FD > /dev/null
		close $FD

		
#		if [[ $popshift == "pop" ]]; then
#			popshift=shift
#		else
#			popshift=pop
#		fi


		# REPLY='"dluna1670@yahoo.com"'

		if [[ $REPLY == "false" ]]; then
			echo "Gearman Queue is empty: $QUEUE" >& 2
			if [ -n "${QUEUES[*]}" ]; then
				repeat=1
				continue
			fi
#			if [[ $QUEUE == "YahooReadyPod" ]]; then
#				echo "Switching to YahooReadyCutoff" >& 2
#				QUEUE=YahooReadyCutoff
#				ADD_APP=
#				repeat=1
#				continue
#			fi
			echo "Sleeping 30 seconds..." >& 2
			sleep 30
			exec "$0" "$@"
			echo false
			exit 1
		fi


		echo "Stack Returned: $REPLY" >&2
		if [[ ${REPLY:0:1} == '"' && ${REPLY:1:1} != "{" ]]; then
			# Assume we have a single username
			USERNAME="${REPLY//\"}"	# "
			REPLY="$USERNAME"
			echo Got username from stack: "$USERNAME" >&2
			if [ -z "$UAGENT" ]; then
				echo Populating random useragent... >&2
				echo >&2
				populate_useragent
				echo >&2
			fi

			if test -f "/root/work/cyrus/facebook/newaccounts/indian/$USERNAME"
			then
				echo -n "UAGENT='$UAGENT' "
				cat /root/work/cyrus/facebook/newaccounts/indian/$USERNAME
				exit 0
			fi

			USE_COOKIES=0 # have to or it doesn't get the sql
			if [ -n "$USE_COOKIES" ]; then
				echo Getting latest cookie... >&2
				echo >&2
				populate_cookies "$USERNAME" 2>&1 > /dev/null
				array.show COOKIE_LIST >&2

				echo >&2
				echo ... SQL debug...	 >&2
				array.show SQL_REPLY >&2
				echo >&2


				false && 
				for key in "${!COOKIE_LIST[@]}"
				do
					# printf "%-20s %s\n"	"$key" "${COOKIE_LIST["$key"]}" >&2
					printf 'ppl cookies.set http://facebook.com "%s=%s; domain=.facebook.com"; ' "$key" "${COOKIE_LIST["$key"]}"
					# cookies.set http://nt4.com "mycookie=bKTmT8ITWkM0-41LHqMz39fq; expires=Sat, 21-Jul-2012 03:09:29 GMT; path=/; domain=.nt4.com"
				done
			fi


			# echo "${!COOKIE_LIST[@]}" >&2
			# echo -n SQL... >&2
			# echo "${!SQL_REPLY[@]}" >&2

			false &&
			if [ -z "${COOKIE_LIST["s"]}" ]; then
				echo no secure cookie >&2
				repeat=1
				continue;
			fi


			(( SKIP_S_COOKIES )) && if [ -n "${COOKIE_LIST["s"]}" ]; then
				echo COOKIE s= Secure cookie found, may skip >&2
				secure=1
				# repeat=1
				# continue
			fi

			false &&
			if [ -z "$ADD_APP" ]; then
				FB_REFRESH=1
			fi
			REAL_IP=$IP

			if test -f "/root/work/cyrus/facebook/newaccounts/users/$USERNAME"
			then
				source /root/work/cyrus/facebook/newaccounts/users/$USERNAME
				# exit 0
			elif test -f "/root/work/cyrus/facebook/newaccounts/parms/$USERNAME"
			then
				source /root/work/cyrus/facebook/newaccounts/parms/$USERNAME
				# exit 0
			elif test -f "/root/work/cyrus/facebook/newaccounts/indian/$USERNAME"
			then
				cat /root/work/cyrus/facebook/newaccounts/indian/$USERNAME
				exit 0
				# exit 0
			elif test -f "/root/work/cyrus/facebook/newaccounts/bj/$USERNAME"
			then
				source /root/work/cyrus/facebook/newaccounts/bj/$USERNAME
				# exit 0
			elif test -f "/root/work/cyrus/facebook/newaccounts/keys/${USERNAME%@*}"
			then
				source /root/work/cyrus/facebook/newaccounts/keys/${USERNAME%@*} "PASS=$PASS"
				# exit 0
			else
				echo "No previous record of this user ('$USERNAME') found in local data... (New User?)" >&2
				# FB_REFRESH=
			fi
			IP=$REAL_IP

			_PASS="$PASS"

			proxy="${SQL_REPLY["proxy"]}" 
			echo "proxy: $proxy" >& 2
			if [[ $proxy =~ ^174.12 || $proxy =~ ^68.1 || $proxy =~ ^1127.131 ]]; then
				echo "banned ip address" >&2
				repeat=1
				continue
			fi

			page="$( curl -s --socks4 $proxy:9999 "http://geoip.ubuntu.com/lookup" --user-agent "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/535.19 (KHTML, LIKE Gecko) Chrome/18.0.1025.162 Safari/535.19" )"
			# Status>OK</Status><CountryCode>US</CountryCode><CountryCode3>USA</CountryCode3>
			COUNTRY="$( echo "$page" | sed 's/.*Status..CountryCode.//' | sed 's/..Count.*//' )"
			echo Country is: $COUNTRY >&2
#			if [[ $COUNTRY != US ]]; then
#				echo exec "$0" "$@"
#			fi
				

			PASS="${SQL_REPLY["password"]}"
			FB_C_USER=${COOKIE_LIST["c_user"]}
			if [ -n "$FB_C_USER" ]; then
				[ -n "$NODEFD" ] && echo "image http://graph.facebook.com/$FB_C_USER/picture?type=large" >&$NODEFD
				loc="$( curl -s --socks4 $proxy:9999 "http://graph.facebook.com/$FB_C_USER/picture" --user-agent "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/535.19 (KHTML, LIKE Gecko) Chrome/18.0.1025.162 Safari/535.19" -i | grep "Location" )"
				(( secure || FB_NOPIC_ONLY )) && [[ $loc =~ jpg ]] &&
				{
					echo Already has a picture: $loc, skipping >&2
					repeat=1
					continue
				}

			fi

			echo Checking yahoo_new_accounts for complete data... >&2
			echo >&2
			populate_yahoo_new_accounts "$USERNAME"

		else
			FB_NEW_ACCOUNT=1
			# ADD_APP=
			# FB_REFRESH=
			# We should have a full record
			if [[ $REPLY == "false" ]]; then
				echo false
				echo "We got a negative reply (false) from gearman" >&2
				exit 1
			fi
 

			# gearman_stack shift YahooReadyPodTest
			# REPLY="$( $STACKCLIENT YahooReadyPodTest shift )"
			# REPLY="$( echo 'Stack {"operation":"pop","stackname":"YahooReadyPodTest"}' | nc -q 10 localhost 4731 |sed 's/.....altemail.*//' |  sed 's/":"/="/g' | sed 's/","/"/g' | sed 's/^..//' | sed 's/..$//' )"
			REPLY="$( echo "$REPLY" | sed 's/.....altemail.*//' |  sed 's/":"/="/g' | sed 's/","/"/g' | sed 's/^..//' | sed 's/..$//' )"
			# echo REPLY: "${REPLY}"
			REPLY="${REPLY//\\}"
			echo REPLY: "${REPLY}" >&2
			echo -n "PROCESSED REPLY: " >&2
			REPLY="$( echo "$REPLY" | sed 's/null/""/g' | sed 's/\\\\[rn]/ /g' | sed 's/":"/="/g' | sed 's/","/" /g' | sed 's/^.//' | sed 's/.$//' )"
			REPLY="${REPLY}\""
			echo "$REPLY" >&2
			eval "${REPLY}"

			NO_ADD_PIC=1	# We don't add a pic during the creation stage, since it seems to affect the "longevity" of Awesomium, and causes holde oauth's to fail later.
			IP="${proxy%:*}"
			EMAIL="${username}"
			FIRST="${firstname}"
			LAST="${lastname}"
			PASS="${password}"
			DAY="${day}"
			MONTH="${month}"
			YEAR="19${year}"
			GENDER="${gender}"

			[[ $EMAIL == "#EANF#" ]] && {
				repeat=1
				continue
			}

			if [[ $IP =~ 68.16 ]]; then
				repeat=1
				continue
			fi

			populate_useragent

			# if [ -z "$TZ" ]
			# then
				TZ="$( echo "SELECT IP2TZ('${IP}') AS TZ" | nc -q 10 localhost 3307 )"
				# [{"IP2TZ('46.23.74.209')":"Europe\/Amsterdam"}]
				TZ="${TZ#*:}"
				TZ="${TZ%\}*}"
				TZ="${TZ%\"*}"
				TZ="${TZ#\"*}"
				TZ="${TZ/\\}"
				echo TZ:$TZ >&2
			# fi
		fi

		PASS="${PASS:-$_PASS}"
		printf "$FORMAT" YAHOO_PASS "${YAHOO_PASS:-$PASS}"
		if [ -z "$PASS" ]; then
			echo "Got all the way to end end, and we have no password ($QUEUE)" >&2
			repeat=1
			continue
		fi
		# {eval "$REPLY"
	done
	# close $FD
}	

dequeue



FORMAT="%s='%s' "

if [ -n "$OVER_IP" ]; then IP=$OVER_IP; fi
printf "$FORMAT" IP "${OVER_IP:-$IP}"
printf "$FORMAT" FIRST "$FIRST"
printf "$FORMAT" LAST "$LAST"
printf "$FORMAT" EMAIL "$EMAIL"
# printf "$FORMAT" PASS "${_PASS:-$PASS}"
# [ -n "$REAL_PASS" ] && printf "$FORMAT" PASS "$REAL_PASS" ||
printf "$FORMAT" PASS "${FB_PASS:-$PASS}"
printf "$FORMAT" YAHOO_PASS "${YAHOO_PASS:-$PASS}"
# [ -z "$FB_REFRESH" ] && {
	printf "$FORMAT" DAY "$DAY"
	printf "$FORMAT" MONTH "$MONTH"
	printf "$FORMAT" YEAR "$YEAR"
	printf "$FORMAT" GENDER "$GENDER"
# }
printf "$FORMAT" TZ "$TZ"
[ -n "$FB_REFRESH" ] &&
	printf "$FORMAT" FB_REFRESH "$FB_REFRESH"

printf "$FORMAT" HEIGHT "$HEIGHT"
printf "$FORMAT" WIDTH "$WIDTH"
printf "$FORMAT" UAGENT "$UAGENT"
printf "$FORMAT" NEW_PIC "1"
[ -n "$NO_ADD_PIC" ] &&
	printf "$FORMAT" NO_ADD_PIC "$NO_ADD_PIC"
printf "$FORMAT" GEARMAN_QUEUE "$QUEUE"
[ -n "$COUNTRY" ] && printf "$FORMAT" COUNTRY "$COUNTRY"
echo


# vim: set ts=3 sts=0 sw=3 noet:
# ./mysql.inc.sh: array assign: line 1: unexpected EOF while looking for matching `''
# ./mysql.inc.sh: array assign: line 185: syntax error: unexpected end of file
