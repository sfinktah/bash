#!/bin/bash



function active_daemons() {
	unset IFS
	DAEMONS=( $( netstat -e -p -l -F -C --numeric-ports --numeric-hosts | sed 's/:::/0.0.0.0:/g' | grep -v '128\.0\.0\.1' | grep -v "::" | grep '^tcp' | sed 's/\(:\|\/\|\s\+\)/\t/g' | cut -f 12 | grep -v '^$' | egrep -v '(httpd|PeopleSim|sshd|^[0-9])' | sort -u ) )
	# DAEMONS=( $( netstat -e -p -l -F -C --numeric-ports --numeric-hosts | sed 's/:::/0.0.0.0:/g' | grep -v '128\.0\.0\.1' | grep -v "::" | grep '^tcp' | sed 's/\(:\|\/\|\s\+\)/\t/g' | cut -f 11,12 | sort -n -u | sed -r 's/(.*)\s(.*)/\2.\1/' | grep -v '^$' | egrep -v '(httpd|PeopleSim|sshd|^[0-9])' ) )
	echo "${DAEMONS[@]}"
}

# doesn't appear to be used
function check_daemons() { # {{{
# proto     recvq       sendq       local       address     foreign     address     state       user        inode       pid         program#{{{
# tcp       0           0           0.0.0.0     111         0.0.0.0     *           LISTEN      root        4711        1675        portmap     
# tcp       0           0           0.0.0.0     52242       0.0.0.0     *           LISTEN      root        6340        -           
# tcp       0           0           0.0.0.0     45140       0.0.0.0     *           LISTEN      root        6421        2774        rpc.mountd  
# tcp       0           0           0.0.0.0     21          0.0.0.0     *           LISTEN      root        6969        2877        vsftpd      
# tcp       0           0           0.0.0.0     53          0.0.0.0     *           LISTEN      root        5098        1888        dnsmasq     
# tcp       0           0           0.0.0.0     22          0.0.0.0     *           LISTEN      root        5125        1900        sshd        
# tcp       0           0           0.0.0.0     1080        0.0.0.0     *           LISTEN      root        7528        3154        ssocks4     
# tcp       0           0           0.0.0.0     4730        0.0.0.0     *           LISTEN      root        151245      10880       gearmand    
# tcp       0           0           0.0.0.0     2049        0.0.0.0     *           LISTEN      root        6320        -           
# tcp       0           0           192.168.1.5 9100        0.0.0.0     *           LISTEN      root        6725        2865        tor         
# tcp       0           0           0.0.0.0     56364       0.0.0.0     *           LISTEN      statd       4763        1694        rpc.statd   
# tcp6      0           0           0.0.0.0     80          0.0.0.0     *           LISTEN      root        7461        3118        apache2     
# tcp6      0           0           0.0.0.0     113         0.0.0.0     *           LISTEN      root        6867        2928        xinetd      
# tcp6      0           0           0.0.0.0     53          0.0.0.0     *           LISTEN      root        5100        1888        dnsmasq     
# tcp6      0           0           0.0.0.0     22          0.0.0.0     *           LISTEN      root        5128        1900        sshd        
# tcp6      0           0           0.0.0.0     25          0.0.0.0     *           LISTEN      root        6866        2928        xinetd      
# tcp6      0           0           0.0.0.0     1241        0.0.0.0     *           LISTEN      root        6865        2928        xinetd      
# tcp6      0           0           0.0.0.0     4730        0.0.0.0     *           LISTEN      root        151246      10880       gearmand    
# tcp6      0           0           0.0.0.0     443         0.0.0.0     *           LISTEN      root        7465        3118        apache2     
# tcp6      0           0           0.0.0.0     445         0.0.0.0     *           LISTEN      root        7300        2800        smbd        
# tcp6      0           0           0.0.0.0     139         0.0.0.0     *           LISTEN      root        7302        2800        smbd        #}}}
	set -f
#	declare DAEMONS
#	DAEMONS=( zero ssocks4 vsftpd sshd apache2 xinetd divert myproxy gearproxy )
	COLUMN_NAMES=( proto recvq sendq local address foreign address state user inode pid program )
	num=0
	linenum=0
	netstat -e -p -l -F -C --numeric-ports --numeric-hosts | sed 's/:::/0.0.0.0:/g' | grep -v '128\.0\.0\.1' | grep -v "::" | grep '^tcp' | sed 's/\(:\|\/\|\s\+\)/\t/g' | while IFS= read -r LINE
	do
		unset IFS
		COLUMN=( $LINE )
		# echo ${!COLUMN[@]}
	#   num=0
	#   echo "Line $linenum: $LINE"
	#   for name in ${COLUMN_NAMES[@]}
	#   do
	#      set record[$name]="${COLUMN[$num]}"
	#      echo record $name = "${COLUMN[$num]}"
	#      echo record $name = "${record[$name]}"
	#		set $name="${COLUMN[$num]}"
	#		
	#      (( num++ ))
	#   done
		address="${COLUMN[4]}"
		user="${COLUMN[8]}"
		pid="${COLUMN[10]}"
		program="${COLUMN[11]}"
		# printf 'port: %s user: %s pid: %s program: %s' "$address" "$user" "$pid" "$program"
		# echo

		if [ "$program" == "divert" -a "$address" != "9339" ]
		then
			continue;
		fi
		lookingFor="$program"

		for index in ${!DAEMONS[@]}
		do
			server=${DAEMONS[$index]}
			if [ "$server" == "$lookingFor" ]
			then
	#			echo "$server found at index $index" ${DAEMONS[${index}]}
				unset DAEMONS[${index}]
				echo "${DAEMONS[@]}"
#				export LEFT
				break
			fi
		done
		(( linenum++ ))
	done | tail -n1
	# echo "${LEFT}"
} # }}}

function changed_daemons() {
	LAST_DAEMONS="${ACTIVE_DAEMONS}"
	ACTIVE_DAEMONS=$( active_daemons )

	LIST_NEW=${ACTIVE_DAEMONS// /\\n}
	LIST_OLD=${LAST_DAEMONS// /\\n}

	DAEMONS_STARTED=$( diff --suppress-common-lines --changed-group-format="%>" --unchanged-group-format=""  <( echo -e "$LIST_OLD" ) <( echo -e "$LIST_NEW" ) )
	DAEMONS_STOPPED=$( diff --suppress-common-lines --changed-group-format="%<" --unchanged-group-format=""  <( echo -e "$LIST_OLD" ) <( echo -e "$LIST_NEW" ) )

	unset IFS

	[ -n "$DAEMONS_STARTED" ] && echo "Daemons started:" ${DAEMONS_STARTED} 
	[ -n "$DAEMONS_STOPPED" ] && echo "DAEMON STOPPED!:" ${DAEMONS_STOPPED} 
}

function daemon_watch() {
	netstat -e -p -l -F -C --numeric-ports --numeric-hosts > /dev/null 2>&1 || exit
	
	for (( ;; ))
	do
		changed_daemons
		sleep 120
	done 
}

