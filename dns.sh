#!/usr/bin/env bash
. includer.inc.sh arrays

declare -a nameservers=( 61.9.133.193 61.9.134.49 61.9.136.251
61.9.138.54 61.9.138.145 61.9.139.169 61.9.140.241 61.9.141.120 61.9.141.237
61.9.142.102 61.9.142.104 61.9.143.5 61.9.143.92 61.9.143.139 61.9.143.220
61.9.144.31 61.9.146.248 61.9.148.116 61.9.148.219 61.9.150.242 61.9.151.70
61.9.151.118 61.9.153.191 61.9.158.72 61.9.160.234 61.9.163.102 61.9.163.105
61.9.164.18 61.9.165.18 61.9.167.53 61.9.167.78 61.9.167.112 61.9.167.134
61.9.167.138 61.9.167.141 61.9.167.145 61.9.167.204 61.9.167.210 61.9.167.244
61.9.169.234 61.9.170.18 61.9.174.227 61.9.184.65 61.9.184.191 61.9.184.228
61.9.184.250 61.9.185.50 61.9.188.33 61.9.190.234 61.9.191.56 61.9.191.57
61.9.191.58 61.9.191.60 61.9.192.164 61.9.192.180 61.9.194.49 61.9.195.193
61.9.196.56 61.9.197.113 61.9.197.116 61.9.198.38 61.9.198.49 61.9.198.111
61.9.198.253 61.9.199.103 61.9.199.114 61.9.199.232 61.9.200.42 61.9.200.94
61.9.200.174 61.9.200.203 61.9.200.248 61.9.201.45 61.9.202.148 61.9.203.73
61.9.203.178 61.9.206.119 61.9.207.1 61.9.208.148 61.9.211.1 61.9.211.2
61.9.211.33 61.9.211.34 61.9.213.81 61.9.214.52 61.9.215.86 61.9.215.250
61.9.219.111 61.9.219.155 61.9.219.179 61.9.220.68 61.9.221.27 61.9.221.169
61.9.222.36 61.9.222.116 61.9.222.232 61.9.223.170 61.9.223.182 61.9.224.164
61.9.226.33 61.9.228.8 61.9.229.36 61.9.229.132 61.9.230.74 61.9.232.66
61.9.240.164 61.9.242.33 61.9.244.102 61.9.244.214 61.9.245.66 61.9.245.178
61.9.245.192 61.9.245.200 61.9.246.47 61.9.247.137 61.9.128.180)
nameservers=( 192.168.1.238 )
chr() {
	printf \\$(printf '%03o' $1)
}
#                                        ad36 0100  .......5.%.[.6..
# 0x0020:  0001 0000 0000 0000 016d 0579 6168 6f6f  .........m.yahoo
# 0x0030:  0363 6f6d 0000 0100 01                   .com........
 
# dns.header.id	16	random
# dns.header.hd1	16	"\x01\x00"
# dns.header.qdcount	16 "\x00\x01"
# dns.header.ancount	16	"\x00\x00"
# dns.header.nscount	16	"\x00\x00"
# dns.header.arcount	16 "\x00\x00"
# dns.header.pstring	8 length + "m"										 # (octet of length) (string)
# dns.header.pstring	8 length + "yahoo"
# dns.header.pstring	8 length + "com"
# dns.header.endcrap	5 "\x00\x00\x01\x00\x01"

dns.hex8() {
	printf -v HEX '\\x%02x' $1
}

dns.query()
{
	# set -o xtrace
	local fqdn="$1"

	local query=
	local sub

	dns.hex8 $(( RANDOM % 256 )); query+="$HEX"
	dns.hex8 $(( RANDOM % 256 )); query+="$HEX"

	explode "." "$fqdn"
	for sub in "${EXPLODED[@]}"; do
		dns.hex8 ${#sub}; query+="$HEX"
		query+="${sub}"
	done
	query+="\x00\x00\x01\x00\x01"
# 	echo $query
	
	REPLY="$query"
}

dns.request() {
	local NAMESERVER="$1"
	local FQDN="$2"
	local DNSPORT=53

	# set -o xtrace

	dns.query "$FQDN"
	# echo -en "$REPLY" | xxd
	exec 6<>/dev/udp/$NAMESERVER/$DNSPORT || echo "Connection failed"
	echo -en "$REPLY" >&6

	# dd bs=2048 count=1 <&6 | xxd
	# exec -&>6
	# echo
} 2>/dev/null

dns.reply() 
{
	FD=6
	array=
	length=1
	# read -u $FD -t 5 -n 1 || return
	sleep 1
	read -r -u $FD -t 0 -n 0 || { echo timeout; return; }
	while read; do
		array+=$REPLY
	done  < <( dd bs=2048 count=$length <&$FD 2>/dev/null | xxd -p )
	el=$?

	char_array=( $(echo -n "$array" | sed 's/../\\\x& /g') )
	hex_array=( $(echo -n "$array" | sed 's/../0x& /g') )
	int_array=()
	for x in "${hex_array[@]}"
	do
	   int_array+=( $(( $x )) )
	done

	echo "${hex_array[@]}"

	# Simple Reply:
	# a950.gi3.akamai.net. 19 IN A 61.9.209.170
	# a950.gi3.akamai.net. 19 IN A 61.9.209.160
	#	 3d 09 d1 a0 / aa

	# 0000000: ffa6 8180 0001 0002 0000 0000 0461 3935  .............a95
	# 0000010: 3003 6769 3306 616b 616d 6169 036e 6574  0.gi3.akamai.net
	# 0000020: 0000 0100 01c0 0c00 0100 0100 0000 0800  ................
	# 0000030:[043d 09d1 a0]c00c00 0100 0100 0000 0800  .=..............
	# 0000040:[043d 09d1 aa]

	cat >/dev/null <<EOT
   RFC-1034

   6.2.1. QNAME=SRI-NIC.ARPA, QTYPE=A

   The query would look like:

                  +---------------------------------------------------+
       Header     | OPCODE=SQUERY                                     |
                  +---------------------------------------------------+
       Question   | QNAME=SRI-NIC.ARPA., QCLASS=IN, QTYPE=A           |
                  +---------------------------------------------------+
       Answer     | <empty>                                           |
                  +---------------------------------------------------+
       Authority  | <empty>                                           |
                  +---------------------------------------------------+
       Additional | <empty>                                           |
                  +---------------------------------------------------+

   The response from C.ISI.EDU would be:

                  +---------------------------------------------------+
       Header     | OPCODE=SQUERY, RESPONSE, AA                       |
                  +---------------------------------------------------+
       Question   | QNAME=SRI-NIC.ARPA., QCLASS=IN, QTYPE=A           |
                  +---------------------------------------------------+
       Answer     | SRI-NIC.ARPA. 86400 IN A 26.0.0.73                |
                  |               86400 IN A 10.0.0.51                |
                  +---------------------------------------------------+
       Authority  | <empty>                                           |
                  +---------------------------------------------------+
       Additional | <empty>                                           |
                  +---------------------------------------------------+

   The header of the response looks like the header of the query, except
   that the RESPONSE bit is set, indicating that this message is a
   response, not a query, and the Authoritative Answer (AA) bit is set
   indicating that the address RRs in the answer section are from
   authoritative data.  The question section of the response matches the
   question section of the query.





   WIKIPEDIA

   RR (Resource record) fields

      Field                                                       Description                                                 Length (octets)

      NAME                                                        Name of the node to which this record pertains              (variable)
      TYPE                                                        Type of RR in numeric form (e.g. 15 for MX RRs)             2
      CLASS                                                       Class code                                                  2
      TTL                                                         Count of seconds that the RR stays valid                    4
      RDLENGTH                                                    Length of RDATA field                                       2
      RDATA                                                       Additional RR-specific data                                 (variable)




   evdns.h

      #define EVDNS_ANSWER_SECTION 0
      #define EVDNS_AUTHORITY_SECTION 1
      #define EVDNS_ADDITIONAL_SECTION 2

      #define EVDNS_TYPE_A     1
      #define EVDNS_TYPE_NS    2
      #define EVDNS_TYPE_CNAME   5
      #define EVDNS_TYPE_SOA       6
      #define EVDNS_TYPE_PTR      12
      #define EVDNS_TYPE_MX   15
      #define EVDNS_TYPE_TXT      16
      #define EVDNS_TYPE_AAAA     28

      #define EVDNS_QTYPE_AXFR 252
      #define EVDNS_QTYPE_ALL    255

      #define EVDNS_CLASS_INET   1


   # 0000000: ffa6 8180 0001 0002 0000 0000 0461 3935  .............a95
   # 0000010: 3003 6769 3306 616b 616d 6169 036e 6574  0.gi3.akamai.net
   # 0000020: 0000 0100 01c0 0c00 0100 0100 0000 0800  ................
   # 0000030:[043d 09d1 a0]c00c00 0100 0100 0000 0800  .=..............
   # 0000040:[043d 09d1 aa]

   skip 6 x 16bit values, read pascal style strings denoting fqdn components until 0000

   read some crap, check class=1, decode and repeat

      TYPE                                                        Type of RR in numeric form (e.g. 15 for MX RRs)             2
      CLASS                                                       Class code                                                  2
      TTL                                                         Count of seconds that the RR stays valid                    4
      RDLENGTH                                                    Length of RDATA field                                       2
      RDATA                                                       Additional RR-specific data                                 (variable)

EOT

   int_array=( ${int_array[@]:12} )
   fqdn=
   while true
   do
	  array_shift x int_array
	  (( x )) || break
	  part=
	  while (( x-- ))
	  do
		 array_shift c int_array
		 printf -v ch \\$(printf '%03o' $c)
		 part+=$ch
	  done
	  fqdn+="$part."
   done
   fqdn=${fqdn%.}
   echo $fqdn:


   array_shift _unk int_array
   array_shift _unk int_array
   array_shift _unk int_array
   array_shift _unk int_array

   while (( ${#int_array[@]} ))
   do
	  
	  # 44 a4 81 80 00 01 00 03 00 00 00 00 04 61 39 35 30 03 67 69 33 06 61 6b 61 6d
	  # 61 69 03 6e 65 74 00 00 01 00 01 c0 0c 00 01 00 01 00 00 00 14 00 04 3d 09 e1
	  # 98 c0 0c 00 01 00 01 00 00 00 14 00 04 3d 09 e1 88 c0 0c 00 01 00 01 00 00 00
	  # 14 00 04 3d 09 e1 96 

	  # --? --? -TYPE   CLASS   -----------TTL  RDLEN   1-- 2-- 3-- 4--
	  # 192 12  0   1   0   1   0   0   0   20  0   4   61  9   225 152 
	  # 192 12  0   1   0   1   0   0   0   20  0   4   61  9   225 136 
	  # 192 12  0   1   0   1   0   0   0   20  0   4   61  9   225 150

	  array_shift _unknown int_array
	  array_shift _unknown int_array
	  array_shift _type int_array
	  array_shift _type int_array
	  array_shift _class int_array
	  array_shift _class int_array
	  array_shift _ttl int_array
	  array_shift _ttl int_array
	  array_shift _ttl int_array
	  array_shift _ttl int_array
	  array_shift _rdlength int_array
	  array_shift _rdlength int_array

	  (( _type != 1 )) && break

	  array_shift o1 int_array
	  array_shift o2 int_array
	  array_shift o3 int_array
	  array_shift o4 int_array

	  ip4="$o1.$o2.$o3.$o4"
	  echo -e "\t$ip4"
   done
}


function crazy_test {
	NAMESERVERS=( 203.12.176.130 61.9.197.116 8.8.8.8 61.9.211.1 )
	# NAMESERVERS=( ${nameservers[@]} )

	zone=1.us.pool.ntp.org
	time -p (
		echo dns.request "$1" "${NAMESERVERS[0]}"
		dns.request "${NAMESERVERS[0]}" "$1"
		dns.reply
		exec -&>6
	)

	NAMESERVERS=( {a..i}.ntpns.org )
	for zone in "${NAMESERVERS[@]}"; do
		rr=$( dig +short -x $zone )
		case $rr in
		  CPE* )
			 echo "Skipping $zone ($rr)"
			 continue
			 ;;
		esac

		echo -n "$zone ($rr): "
		time -p (
		dns.request "$zone" 0.us.pool.ntp.org # a950.gi3.akamai.net
		dns.reply
		exec -&>6
		)
		echo
		echo
		echo
	done
	exit
}

dns.request 8.8.8.8 nt4.com 
dns.reply
exec -&>6
# vim: set ts=3 sts=0 sw=3 noet:
