#!/usr/bin/env bash

SHOWWRITE=0
SHOWWRITEERROR=1
open() {
	local argc=$#
	local filename=$1
	local mode=$2
	local fd=<( true )		# allocate ourselves a temporary fd 
	local pipe

	cat < $fd > /dev/null	# use the fd, so it is open for reuse
	fd=${fd##/*/}				# trim the non-numeric stuff (/dev/fd/64)
	(( fd -- ))

	(( !argc ))     && eval "exec $fd<>/dev/null"		# no arguments, just allocate fd
	(( argc == 1 )) && eval "exec $fd<&\"$filename\""	# no mode, assume read
	(( argc == 2 )) && case mode in
								r ) pipe='<&' 
									;;
								w ) pipe='>&' 
									;;
								* ) pipe='<>'
							 esac && 
							 eval "exec $fd$pipe\"$filename\""
	el=$?
	FD="/dev/fd/$fd"		# "export" FD into global scope 
	# lsof -np $$
	return $?				# return errorlevel of exec (hopefully)
}


write() {
	# fd=${1##/*/}				# trim the non-numeric stuff (/dev/fd/64)
	local fd=$1
	shift 

	(( SHOWWRITE )) && echo "Writing '$*' to $fd ..."
	echo -n "$*" > $fd			# must use CR without LF for EOL
	el=$?										# should check for non-zero response indicating non-existant device
	if [ "$el" -ne "0" ]; then
		(( SHOWWRITEERROR )) && echo "ERROR WRITING $fd"
		return 1
	fi


}

close() {
	while [ -n "$1" ]; do
		fd=${1##/*/}				# trim the non-numeric stuff (/dev/fd/64)
		eval "exec $fd<&-"
		shift
	done
}

fgets() {
	local fd="$1"
	REPLY=
	# IFS=$'\x0d\x0a' read -t 60 -d $'\x0d' -r < $fd
	pushifs ''
	IFS= read -t 3 -r < $fd
	el=$?
	REPLY=${REPLY%$'\x0d'}
	popifs
	echo "$REPLY"
	# printf '%03s,%1s %s\n' ${#REPLY} $el "$REPLY"
	return $el
}


gsm_fgets() {
	local lines=0
	local blanks=0
	local error=0
	local at=0
	local ok=0
	local unknown=0
	local fd=$1
	local line
	# dd if=$fd of=/dev/null bs=1 count=1
	while true 
	do
		setifs ''
		read -t 1 -n 1024 -r -d $'\x0a' -a line < $fd
		el=$?
		setifs
		declare -p line > /dev/stderr
		[ "${#line}" -eq "0" ] &&
			(( blanks++ )) || 
		case ${line[0]} in
			AT* ) (( at++ )) 			# Must be in ECHO mode, this is the same as a new line basically, and we expect to receive this first
				;;
			OK ) (( ok++ ))
				;;
			ERROR ) (( error++ ))
				;;
			* ) (( unknown++ ))
		esac

		(( lines ++ ))

		# (( ok || error )) && break
		echo lines: $lines  at: $at  blanks: $blanks > /dev/stderr
		(( lines > 1 || at || blanks )) || continue
		declare -p line
		return $el
		
	done
}

gsm_read() {
	local -a lines
	local -a line_pos=0
	while line=$( gsm_fgets $FD ); do
		# echo $line
		eval $line
		echo ${line[@]}
		lines[${#lines[*]}]="${line[@]}"
		# lines+=( ${line[@]} )
		case ${line[0]} in
			OK | ERROR ) break
		esac
	done
	declare -p lines
}

__test() {
	open /dev/cu.HU*Modem rw
	lsof -np $$ | grep Modem
	(( LINUX )) && stty -F $FD -inlcr -icrnl -igncr
	(( DARWIN )) && stty -f /dev/cu.HU*Modem 115200 -inlcr -icrnl igncr
	echo -en "AT E1 \r" > $FD
	gsm_read
	close $FD


	lsof -n -p $$ | grep '6[0-9]u'

}

