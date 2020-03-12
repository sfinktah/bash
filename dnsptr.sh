#!/usr/bin/env bash
. includer.inc.sh arrays

chr() {
	printf \\$(printf '%03o' $1)
}

#                                        ad36 0100  .......5.%.[.6.. {{{
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
# dns.header.endcrap	5 "\x00\x00\x01\x00\x01" }}}

dns.hex8() {
	printf -v HEX '\\x%02x' $1
}

dns.query()
{

	#	               +---------------------------------------------------+
	#	    Header     | OPCODE=SQUERY, RESPONSE, AA                       |
	#	               +---------------------------------------------------+
	#	    Question   | QNAME=65.0.6.26.IN-ADDR.ARPA.,QCLASS=IN,QTYPE=PTR |
	#	               +---------------------------------------------------+
	#	    Answer     | 65.0.6.26.IN-ADDR.ARPA.    PTR     ACC.ARPA.      |
	#	               +---------------------------------------------------+
	#	    Authority  | <empty>                                           |
	#	               +---------------------------------------------------+
	#	    Additional | <empty>                                           |
	#	               +---------------------------------------------------+
	# set -o xtrace

# 5e9e 0100 0001 0000 0000 0000 0132 0130 0130 0331 3237 0769 6e2d 6164 6472 0461 7270 6100 000c 0001                    
# d46e 0100 0001 0000 0000 0000 0132 0130 0130 0331 3237 0769 6e2d 6164 6472 0461 7270 6100 000c 0001

   # d46e 8583  .....5...0...n..
   # 	0x0020:  0001 0000 0000 0000 0132 0130 0130 0331  .........2.0.0.1
   # 	0x0030:  3237 0769 6e2d 6164 6472 0461 7270 6100  27.in-addr.arpa.
   # 	0x0040:  000c 0001                                ....

	#	09:33:57.423779 IP proxy.lan.50885 > wndr.lan.domain: 5926+ PTR? 6.1.168.192.in-addr.arpa. (42)
	#		0x0000:  4500 0046 5e98 0000 ff11 d8c9 c0a8 0106  E..F^...........
	#		0x0010:  c0a8 01ee c6c5 0035 0032 10a4 1726 0100  .......5.2...&..
	#		0x0020:  0001 0000 0000 0000 0136 0131 0331 3638  .........6.1.168
	#		0x0030:  0331 3932 0769 6e2d 6164 6472 0461 7270  .192.in-addr.arp
	#		0x0040:  6100 000c 0001                           a.....
	#	09:33:57.424175 IP wndr.lan.domain > proxy.lan.50885: 5926* 1/0/0 PTR proxy.lan. (65)
	#		0x0000:  4500 005d 0000 4000 4011 b64b c0a8 01ee  E..]..@.@..K....
	#		0x0010:  c0a8 0106 0035 c6c5 0049 769c 1726 8580  .....5...Iv..&..
	#		0x0020:  0001 0001 0000 0000 0136 0131 0331 3638  .........6.1.168
	#		0x0030:  0331 3932 0769 6e2d 6164 6472 0461 7270  .192.in-addr.arp
	#		0x0040:  6100 000c 0001 c00c 000c 0001 0000 0000  a...............
	#		0x0050:  000b 0570 726f 7879 036c 616e 00         ...proxy.lan.

	local fqdn="$1"

	local query=
	local sub

	dns.hex8 $(( RANDOM % 256 )); query+="$HEX"
	dns.hex8 $(( RANDOM % 256 )); query+="$HEX"
	query+="\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00"
	explode "." "$fqdn"
	for sub in "${EXPLODED[@]}"; do
		dns.hex8 ${#sub}; query+="$HEX"
		query+="${sub}"
	done
	query+="\x00\x00\x0c\x00\x01"
 	# echo $query
	
	REPLY="$query"
}

dns.request() {
	local NAMESERVER="$1"
	local FQDN="$2"
	local DNSPORT=53

	# set -o xtrace

	dns.query "$FQDN"
	echo
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
	GEARMAN_TIMEOUT=2
	# read -u $FD -t 5 -n 1 || return
	sleep 1
	read -r -u $FD -t 0 -n 0 || { echo timeout; return; }
	while read; do
		array+=$REPLY
	done  < <( dd bs=2048 count=$length <&$FD 2>/dev/null | xxd -p )
	el=$?

	# char_array=( $(echo -n "$array" | sed 's/../\\\x& /g') )
	hex_array=( $(echo -n "$array" | sed 's/../0x& /g') )
	int_array=()
	for x in "${hex_array[@]}"
	do
	   int_array+=( $(( $x )) )
	done

	# Simple Reply: {{{
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

	  #define EVDNS_TYPE_A	   1
	  #define EVDNS_TYPE_NS	   2
	  #define EVDNS_TYPE_CNAME   5
	  #define EVDNS_TYPE_SOA	   6
	  #define EVDNS_TYPE_PTR	  12
	  #define EVDNS_TYPE_MX	  15
	  #define EVDNS_TYPE_TXT	  16
	  #define EVDNS_TYPE_AAAA	  28

	  #define EVDNS_QTYPE_AXFR 252
	  #define EVDNS_QTYPE_ALL	 255

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

# }}}

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
   # echo dns.reply: FQDN "'$fqdn'" " " 


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

	  (( _type != 12 )) && {
	  echo -e "\t_type ($_type) != 1" 
	  break
   }

#	  array_shift o1 int_array
#	  array_shift o2 int_array
#	  array_shift o3 int_array
#	  array_shift o4 int_array
#	  array_shift o5 int_array
#	  array_shift o6 int_array

	  # ip4="$o1.$o2.$o3.$o4"
	  # echo -e "\t$ip4"
	  echo "${int_array[@]}"

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
   echo $fqdn
	  break
   done
}

NAMESERVERS=( 192.168.1.238 203.12.176.130 61.9.197.116 8.8.8.8 61.9.211.1 )
cat spam_check.ips | 
while read -r 
do
	explode "." "$REPLY"
	rhost="${EXPLODED[3]}.${EXPLODED[2]}.${EXPLODED[1]}.${EXPLODED[0]}.in-addr.arpa."

	for zone in "${NAMESERVERS[@]}"; do
	   printf "%-16s:\t" "$REPLY"
	   # echo -n "$REPLY: " # $rhost @$zone : "
	   time -p (
		  dns.request "$zone" "$rhost"
		  dns.reply
		  exec -&>6
	   )
	   break
	done
done
exit
# vim: set ts=4 sts=0 sw=3 noet:
