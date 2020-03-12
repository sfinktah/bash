#!/usr/bin/env bash

. ../bash/fds.sh
. ../bash/explode.inc.sh

print_ifs() {
	echo -n IFS: && echo -n "$IFS" | xxd
}

declare -A exploded_url
explode_url() {
	# print_ifs
	local url="$1"
	# echo $url
	explode "/" "$url" 
	# declare -p EXPLODED
	# declare -a exploded='([0]="scheme:" [1]="" [2]="domain:port" [3]="path?query_string#fragment_id *")'

	local domain=${EXPLODED[2]%:*}
	local port=${EXPLODED[2]#*:}
	# IFS=/ path=$( echo "${EXPLODED[*]:3}" )
	IFS=/ path=( "${EXPLODED[*]:3}" )
	#  IFS=_ echo eval "path='$path'"		# TODO: escape single quotations 
	# IFS=_ eval "path='$path'"		# TODO: escape single quotations 
	# bar="$( IFS=/ echo "${EXPLODED[*]:3}" )"

	# IFS=" "
	# declare -p bar
	# path=${path%#*}

	local default_port
	local scheme=${EXPLODED[0]%:}
	# echo scheme: $scheme domain: $domain port: $port path: $path
	case "$scheme" in 
		http ) default_port=80 ;;
		https ) default_port=443 ;;
		* ) echo unknown scheme "'$scheme'"; return 1
	esac
	[ "$domain" == "$port" ] && port=$default_port

	# echo scheme: $scheme domain: $domain port: $port path: $path
	exploded_url["scheme"]="${scheme}"		# TODO: Does ${var} has to be quoted?
	exploded_url["port"]="${port}"
	exploded_url["domain"]="${domain}"
	exploded_url["path"]="${path}"	

	local d=$( declare -p exploded_url )
	# echo "$d"
	eval "$d"
	d=${d#*\'}
	d=${d%\'*}
	# echo "$d"
	setifs
}


inacon() {
	setifs
	# clear

	# URL3="http://www.inacon.de/glossary/MSIN.php"
	# eval "declare -A url=$( explode_url "${URL3}" )"		# declare -A url='( [scheme]="http" [domain]="www.inacon.de" [path]="glossary/MSIN.php"  [port]="80" )'
	# echo keys=${!exploded_url[@]}

	shopt -s extglob
	# explode_url "http://www.msdncom.com/soft/1042317.htm"
	explode_url "http://www.inacon.de/glossary/$1.php"
	open "/dev/tcp/${exploded_url["domain"]}/${exploded_url["port"]}" "rw"
	CRLF=$'\x0d\x0a'
	setifs
	write $FD "GET /${exploded_url["path"]} HTTP/1.1$CRLF"
	write $FD "Host: ${exploded_url["domain"]}$CRLF"
	write $FD "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/534.50 (KHTML, like Gecko) Version/5.1 Safari/534.50$CRLF"
	write $FD "Accept: */*$CRLF"
	write $FD "Accept-Language: en-us$CRLF"
	write $FD "$CRLF"
	# <td class="farbzelle_8" align="left">Location Area Code</td>
	while line=$( fgets $FD ); do
		# echo -n "$line" | xxd
		# And here we have Bash Patterns:
		if [[ "$line" =~ meta.name..Keyword ]]
		then
			keywords=$line
		fi
		if [[ "$line" =~ farbzelle_8.*left ]]
		then
			line=${line#<*>}
			# echo "$line"
		fi
		#           <p><strong>Abbreviation for Mobile Station Identification Number</strong></p>
		if [[ "$line" =~ .p..strong. ]]
		then
			tags='<?(/)+([a-z])>'
			line=${line//$tags}
			space=" "
			# line=${line%%$'\x20'}
			line=${line##$space}
			HEADING=$line
		fi
		if [[ "$line" == *_text1* ]]
		then
			# echo copying
			COPY=
			COPY_UNTIL="</tr>"
		fi
		if [[ "$line" =~ Search: ]]
		then
			break
		fi
		if [ -n "$COPY_UNTIL" ]
		then
			# echo copying "$line"
			COPY+=$line
			if [ "$line" != "${line/${COPY_UNTIL}/}" ]
			then 
				# echo found
				COPY_UNTIL=
			fi

		fi
		# (( n )) && echo "$line"
	done

	close $FD

	# if [ -n "$COPY" ]; then echo "Copy: $COPY"; fi

	strong="<strong>"
	unstrong="</strong>"
	underline=$'\x1f'
	bold=$'\x02'
	normal=$'\x0f'
	r="<td id=\"_text1\" class=\"text\" >(.*)</td>"
	[ -n "$COPY" ] &&
		[[ "$COPY" =~ $r ]] && 
		{
			COPY=${BASH_REMATCH[1]}
			COPY=${COPY//$strong/$underline}
			COPY=${COPY//$unstrong/$normal}
			printf "$bold%s$normal %s\n" "${HEADING}" "${COPY}"
		}

	#	<td id="_text1" class="text" >
	#	<strong> Fixed Dialling Numbers </strong>
	#	are stored in the SIM (Subscriber Identity Module) / USIM (UMTS Subscriber Identity Module).<strong> FDN </strong>
	#	entries are composed of a Destination Address / Supplementary Service Control and a service code.</td>
	#	</tr>
	#	<tr>
}

# inacon $1
