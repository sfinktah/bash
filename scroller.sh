#!/bin/bash

_SECONDS=0
color() {
	printf '\e[%dm' "$1"
}
bold() {
	color 1
}

unbold() {
	color 22
}

scroller() {
	SCREEN_SCROLLER=1
}

noscroller() {
	SCREEN_SCROLLER=
}

stopscroll() {
	(( SCROLLER )) && kill -INT "$SCROLLER"
}


sttysize() {
	read h w < <( stty size 2>/dev/null )
	el=$?
	if (( el == 0 )); then
	        SCREEN_WIDTH=${w}
	        SCREEN_HEIGHT=${h}
	        echo -en "\e[1;1H"
	        echo -en "\e[7m"
	        PPL_STATUS_LINE=""
	        for (( i=0; i<SCREEN_WIDTH; i++ )); do
	                PPL_STATUS_LINE+=" "
	        done
	        echo -n "${PPL_STATUS_LINE}"
	        echo -en "\e[27m"
	        echo -ne "\e[2;$(( SCREEN_HEIGHT ))r"
	        echo -en "\e[2;1H"
	fi
	return $el
}

drawstatusline() {
	if (( ! SCREEN_SCROLLER )); then 
		return
	fi
	(( ! SCREEN_WIDTH )) && sttysize
	if (( SCREEN_SCROLLER )); then
		(( _SECONDS ++ ))
		if (( _SECONDS > SCREEN_WIDTH )); then
			_SECONDS=0
		fi

		local len=${#PPL_STATUS_LINE}
		local scrolled=""
		local offset=$_SECONDS
		# echo offset: $offset
		scrolled+="${PPL_STATUS_LINE:$offset}"
		scrolled+="${PPL_STATUS_LINE:0:$offset}"

		local len
		len="${#PPL_STATUS_LINE}"
		if (( len > SCREEN_WIDTH )); then
			scrolled="${scrolled:0:$SCREEN_WIDTH}"
		fi

	fi
	# scrolled="${scrolled-$PPL_STATUS_LINE}"
	echo -en "\e7"
	echo -en '\e[1;1H'
	echo -en "\e[7m"
	echo -en "\r"
	echo -n "${scrolled}"
	echo -en "\e[27m"
	echo -en "\e8"
}

statusmake() {
	local right
	printf -v right "%${SCREEN_WIDTH}s" "$PPL_STATUS_RIGHT"
	local leftlen
	leftlen="${#PPL_STATUS_LEFT}"
	PPL_STATUS_LINE="${PPL_STATUS_LEFT}${right:$leftlen}"
	drawstatusline
}

statusleft() {
	PPL_STATUS_LEFT=" ${1} "
	statusmake
}

statusright() {
	PPL_STATUS_RIGHT=" ${1} "
	statusmake
}



ansion() {
	sttysize
}

ansioff() {
	echo -ne "\e[r\ec"
}

scrollinit() {
	ansion
	statusleft "$( uname -a )"
	statusright "$( uname -a )"
	statusmake
	scroller
}

pipebg() {
	rm -f /tmp/scroller2
	mkfifo /tmp/scroller2
	exec 6<>/tmp/scroller2
	clear
	echo
	scrollinit
	while true
	do
		sleep 1
		unset COMMANDS
		if read -t 0 -r -u 6 -a COMMANDS
		then
			if read -r -u 6 -a COMMANDS
			then
				echo ${COMMANDS[0]} "${COMMANDS[@]:1}"
				${COMMANDS[0]} "${COMMANDS[*]:1}"
			fi
		fi
		drawstatusline
	done
}

