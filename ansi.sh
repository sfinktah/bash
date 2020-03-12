color() {
	printf '\e[%dm' "$1"
}
bold() {
	color 1
}

unbold() {
	color 22
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
	echo -en "\e7"
	echo -en '\e[1;1H'
	echo -en "\e[7m"
	echo -en "\r"
	echo -n "${PPL_STATUS_LINE}"
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
	echo "statusleft $@" > /tmp/scroller2
	return
	PPL_STATUS_LEFT="${1}"
	statusmake
}

scrollinit() {
	echo "scrollinit" "$@" > /tmp/scroller2
}


statusmiddle() {
	PPL_STATUS_MIDDLE="{$@}"
}

statusright() {
	echo "statusright $PPL_STATUS_MIDDLE     $@" > /tmp/scroller2
	return
	PPL_STATUS_RIGHT="${1}"
	statusmake
}



ansion() {
	sttysize
}

ansioff() {
	echo -ne "\e[r\ec"
}
