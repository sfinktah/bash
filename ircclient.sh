#!/usr/bin/env bash
BASEDIR=$(cd `dirname $0` && pwd) ; cd $BASEDIR
. ./irclib.inc.sh

unset on251

on251() 
{
	write OPER cyrus indigo
	write LIST :#bots
	write WHO :#bots
}

# [ 352 ] :irc5.foonet.com 352 ec #bots bro45oks rox-9A2076D7 spanky.foonet.com brooks64628932|rediffmail H? :3 ./gzap.php;11584
on352() {
	CHANNEL=$4
	USER=$5
	VHOST=$6
	SERVER=$7
	NAME=$8
	STATUS=$9
	
	[[ ! "$*" =~ "CrossTalk" ]] && addBot "$NAME"
}

on315() {
	echo "${presentBots[@]}"
	exit
}

irc.start
