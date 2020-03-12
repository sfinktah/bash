#!/usr/bin/env bash
. includer.inc.sh arrays BinaryString

## Add an extra method to BinaryString
function BinaryString.dns_implode_string
{
   scope 

   local fqdn=
   local part
   local x
   local c
   local buf
   local pos

   put $this.pos into pos
   put $this.buf into buf
   buf=${buf:$(( pos * 2))}

   while true
   do
	  $this.NextByte x

	  (( x )) || break
	  part=
	  while (( x-- ))
	  do
		 $this.NextByte c
		 printf -v ch \\$(printf '%03o' $c )
		 part+=$ch
	  done
	  fqdn+="$part."
   done
   fqdn=${fqdn%.}

   local "$1" && upvar $1 "$fqdn"
}



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

	#	http://tools.ietf.org/html/rfc1035#page-12

	#	Various objects and parameters in the DNS have size limits.  They are
	#	listed below.  Some could be easily changed, others are more
	#	fundamental.
	#	
	#	labels          63 octets or less
	#	
	#	names           255 octets or less
	#	
	#	TTL             positive values of a signed 32 bit number.
	#	
	#	UDP messages    512 octets or less

	#	
	#	Domain names in messages are expressed in terms of a sequence of labels.
	#	Each label is represented as a one octet length field followed by that
	#	number of octets.  Since every domain name ends with the null label of
	#	the root, a domain name is terminated by a length byte of zero.  The
	#	high order two bits of every length octet must be zero, and the
	#	remaining six bits of the length field limit the label to 63 octets or
	#	less.
	#	
	#	To simplify implementations, the total length of a domain name (i.e.,
	#	label octets and label length octets) is restricted to 255 octets or
	#	less.


	#	                                    1  1  1  1  1  1
	#	      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
	#	    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
	#	    |                                               |
	#	    /                                               /
	#	    /                      NAME                     /
	#	    |                                               |
	#	    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
	#	    |                      TYPE                     |
	#	    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
	#	    |                     CLASS                     |
	#	    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
	#	    |                      TTL                      |
	#	    |                                               |
	#	    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
	#	    |                   RDLENGTH                    |
	#	    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--|
	#	    /                     RDATA                     /
	#	    /                                               /
	#	    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+



	#	NAME            an owner name, i.e., the name of the node to which this
	#	                resource record pertains.
	#	
	#	TYPE            two octets containing one of the RR TYPE codes.
	#	
	#	CLASS           two octets containing one of the RR CLASS codes.
	#	
	#	TTL             a 32 bit signed integer that specifies the time interval
	#	                that the resource record may be cached before the source
	#	                of the information should again be consulted.  Zero
	#	                values are interpreted to mean that the RR can only be
	#	                used for the transaction in progress, and should not be
	#	                cached.  For example, SOA records are always distributed
	#	                with a zero TTL to prohibit caching.  Zero values can
	#	                also be used for extremely volatile data.
	#	
	#	RDLENGTH        an unsigned 16 bit integer that specifies the length in
	#	                octets of the RDATA field.
	#	
	#	
	#	RDATA           a variable length string of octets that describes the
	#	                resource.  The format of this information varies
	#	                according to the TYPE and CLASS of the resource record.
	#	
	#	3.2.2. TYPE values
	#	
	#	TYPE fields are used in resource records.  Note that these types are a
	#	subset of QTYPEs.
	#	
	#	TYPE            value and meaning
	#	
	#	A               1 a host address
	#	
	#	NS              2 an authoritative name server
	#	
	#	MD              3 a mail destination (Obsolete - use MX)
	#	
	#	MF              4 a mail forwarder (Obsolete - use MX)
	#	
	#	CNAME           5 the canonical name for an alias
	#	
	#	SOA             6 marks the start of a zone of authority
	#	
	#	MB              7 a mailbox domain name (EXPERIMENTAL)
	#	
	#	MG              8 a mail group member (EXPERIMENTAL)
	#	
	#	MR              9 a mail rename domain name (EXPERIMENTAL)
	#	
	#	NULL            10 a null RR (EXPERIMENTAL)
	#	
	#	WKS             11 a well known service description
	#	
	#	PTR             12 a domain name pointer
	#	
	#	HINFO           13 host information
	#	
	#	MINFO           14 mailbox or mail list information
	#	
	#	MX              15 mail exchange
	#	
	#	TXT             16 text strings
	#	
	#	3.2.3. QTYPE values
	#	
	#	QTYPE fields appear in the question part of a query.  QTYPES are a
	#	superset of TYPEs, hence all TYPEs are valid QTYPEs.  In addition, the
	#	following QTYPEs are defined:
	#	
	#	AXFR            252 A request for a transfer of an entire zone
	#	
	#	MAILB           253 A request for mailbox-related records (MB, MG or MR)
	#	
	#	MAILA           254 A request for mail agent RRs (Obsolete - see MX)
	#	
	#	*               255 A request for all records
	#	
	#	3.2.4. CLASS values
	#	
	#	CLASS fields appear in resource records.  The following CLASS mnemonics
	#	and values are defined:
	#	
	#	IN              1 the Internet
	#	
	#	CS              2 the CSNET class (Obsolete - used only for examples in
	#	                some obsolete RFCs)
	#	
	#	CH              3 the CHAOS class
	#	
	#	HS              4 Hesiod [Dyer 87]
	#	
	#	3.2.5. QCLASS values
	#	
	#	QCLASS fields appear in the question section of a query.  QCLASS values
	#	are a superset of CLASS values; every CLASS is a valid QCLASS.  In
	#	addition to CLASS values, the following QCLASSes are defined:
	#	
	#	*               255 any class
	#	
	#	3.3. Standard RRs
	#	
	#	The following RR definitions are expected to occur, at least
	#	potentially, in all classes.  In particular, NS, SOA, CNAME, and PTR
	#	will be used in all classes, and have the same format in all classes.
	#	Because their RDATA format is known, all domain names in the RDATA
	#	section of these RRs may be compressed.
	#	
	#	<domain-name> is a domain name represented as a series of labels, and
	#	terminated by a label with zero length.  <character-string> is a single
	#	length octet followed by that number of characters.  <character-string>
	#	is treated as binary information, and can be up to 256 characters in
	#	length (including the length octet).
	#	
	#	
	#	
	#	
	#	All communications inside of the domain protocol are carried in a single
	#	format called a message.  The top level format of message is divided
	#	into 5 sections (some of which are empty in certain cases) shown below:
	#	
	#	    +---------------------+
	#	    |        Header       |
	#	    +---------------------+
	#	    |       Question      | the question for the name server
	#	    +---------------------+
	#	    |        Answer       | RRs answering the question
	#	    +---------------------+
	#	    |      Authority      | RRs pointing toward an authority
	#	    +---------------------+
	#	    |      Additional     | RRs holding additional information
	#	    +---------------------+
	#	
	#	
	#	
	#	The header contains the following fields:
	#	
	#	                                    1  1  1  1  1  1
	#	      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
	#	    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
	#	    |                      ID                       |
	#	    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
	#	    |QR|   Opcode  |AA|TC|RD|RA|   Z    |   RCODE   |
	#	    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
	#	    |                    QDCOUNT                    |
	#	    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
	#	    |                    ANCOUNT                    |
	#	    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
	#	    |                    NSCOUNT                    |
	#	    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
	#	    |                    ARCOUNT                    |
	#	    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
	#	
	#	
	#	QDCOUNT         an unsigned 16 bit integer specifying the number of
	#	                entries in the question section.
	#	
	#	ANCOUNT         an unsigned 16 bit integer specifying the number of
	#	                resource records in the answer section.
	#	
	#	NSCOUNT         an unsigned 16 bit integer specifying the number of name
	#	                server resource records in the authority records
	#	                section.
	#	
	#	ARCOUNT         an unsigned 16 bit integer specifying the number of
	#	                resource records in the additional records section.



	#	The answer, authority, and additional sections all share the same
	#	format: a variable number of resource records, where the number of
	#	records is specified in the corresponding count field in the header.
	#	Each resource record has the following format:
	#	                                    1  1  1  1  1  1
	#	      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
	#	    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
	#	    |                                               |
	#	    /                                               /
	#	    /                      NAME                     /
	#	    |                                               |
	#	    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
	#	    |                      TYPE                     |
	#	    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
	#	    |                     CLASS                     |
	#	    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
	#	    |                      TTL                      |
	#	    |                                               |
	#	    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
	#	    |                   RDLENGTH                    |
	#	    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--|
	#	    /                     RDATA                     /
	#	    /                                               /
	#	    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
	#	
	#	where:
	#	
	#	NAME            a domain name to which this resource record pertains.
	#	
	#	TYPE            two octets containing one of the RR type codes.  This
	#	                field specifies the meaning of the data in the RDATA
	#	                field.
	#	
	#	CLASS           two octets which specify the class of the data in the
	#	                RDATA field.
	#	
	#	TTL             a 32 bit unsigned integer that specifies the time
	#	                interval (in seconds) that the resource record may be
	#	                cached before it should be discarded.  Zero values are
	#	                interpreted to mean that the RR can only be used for the
	#	                transaction in progress, and should not be cached.
	#	
	#	
	#	
	#	
	#	
	#	Mockapetris                                                    [Page 29]
	#	 
	#	RFC 1035        Domain Implementation and Specification    November 1987
	#	
	#	
	#	RDLENGTH        an unsigned 16 bit integer that specifies the length in
	#	                octets of the RDATA field.
	#	
	#	RDATA           a variable length string of octets that describes the
	#	                resource.  The format of this information varies
	#	                according to the TYPE and CLASS of the resource record.
	#	                For example, the if the TYPE is A and the CLASS is IN,
	#	                the RDATA field is a 4 octet ARPA Internet address.
	#	
	#	4.1.4. Message compression
	#	
	#	In order to reduce the size of messages, the domain system utilizes a
	#	compression scheme which eliminates the repetition of domain names in a
	#	message.  In this scheme, an entire domain name or a list of labels at
	#	the end of a domain name is replaced with a pointer to a prior occurance
	#	of the same name.
	#	
	#	The pointer takes the form of a two octet sequence:
	#	
	#	    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
	#	    | 1  1|                OFFSET                   |
	#	    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
	#	
	#	The first two bits are ones.  This allows a pointer to be distinguished
	#	from a label, since the label must begin with two zero bits because
	#	labels are restricted to 63 octets or less.  (The 10 and 01 combinations
	#	are reserved for future use.)  The OFFSET field specifies an offset from
	#	the start of the message (i.e., the first octet of the ID field in the
	#	domain header).  A zero offset specifies the first byte of the ID field,
	#	etc.

	# ...

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
	query+="\x00\x00\xff\x00\x01"
 	# echo $query
	
	REPLY="$query"
}

dns.request() {
	local NAMESERVER="$1"
	local FQDN="$2"
	local DNSPORT=53


	dns.query "$FQDN"
	echo
	exec 6<>/dev/udp/$NAMESERVER/$DNSPORT || echo "Connection failed"
	echo -en "$REPLY" >&6

	# dd bs=2048 count=1 <&6 | xxd
	# exec -&>6
	# echo
} 2>/dev/null

dechex() 
{
   declare -r HEX_DIGITS="0123456789abcdef"

   dec_value=$1
   hex_value=""

   until [ $dec_value == 0 ]; do

	  rem_value=$((dec_value % 16))
	  dec_value=$((dec_value / 16))

	  hex_digit=${HEX_DIGITS:$rem_value:1}

	  hex_value="${hex_digit}${hex_value}"

   done

   echo -e "${hex_value}"
}

dns.implode.string()
{
   local argc=$#
   local fqdn=
   local part
   local x
   local c

   while true
   do
	  x=$1
	  shift
	  (( x )) || break
	  part=
	  while (( x-- ))
	  do
		 c=$1
		 shift
		 printf -v ch \\$(printf '%03o' $c)
		 part+=$ch
	  done
	  fqdn+="$part."
   done
   REPLY=${fqdn%.}
   COUNT=$(( argc - $# ))
}


dns.reply() 
{
   FD=6
   array=
   local -i ptr=0
   length=1
   GEARMAN_TIMEOUT=2
   # read -u $FD -t 5 -n 1 || return
   sleep 1
   read -r -u $FD -t 0 -n 0 || { echo timeout; return; }
   while read; do
	  array+=$REPLY
   done  < <( dd bs=2048 count=$length <&$FD 2>/dev/null | xxd -p )
   # done  < <( dd bs=2048 count=$length <&$FD 2>/dev/null | new BinaryString buf stdin )
   el=$?

   new BinaryString buf stdin < <( echo -n "$array" | xxd -r -p )
   # buf.tostring | xxd

   # char_array=( $(echo -n "$array" | sed 's/../\\\x& /g') )
   # echo "${char_array[@]}"
   # echo -n "${array[@]}" | xxd -p -r | xxd
   hex_array=( $(echo -n "$array" | sed 's/../0x& /g') )
   int_array=()
   for x in "${hex_array[@]}"
   do
	  int_array+=( $(( $x )) )
   done

   #                                    1  1  1  1  1  1
   #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
   #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
   #    |                      ID                       |
   #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
   #    |QR|   Opcode  |AA|TC|RD|RA|   Z    |   RCODE   |
   #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
   #    |                    QDCOUNT                    |
   #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
   #    |                    ANCOUNT                    |
   #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
   #    |                    NSCOUNT                    |
   #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
   #    |                    ARCOUNT                    |
   #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
   #
   local h_id=0
   local h_bits=0
   local h_qdcount=0
   local h_adcount=0
   local h_nscount=0
   local h_arcount=0

   buf.NextWord h_id
   buf.NextWord h_bits
   buf.NextWord h_qdcount
   buf.NextWord h_adcount
   buf.NextWord h_nscount
   buf.NextWord h_arcount


   ## question section

   #                                    1  1  1  1  1  1
   #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
   #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
   #    |                                               |
   #    /                     QNAME                     /
   #    /                                               /
   #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
   #    |                     QTYPE                     |
   #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
   #    |                     QCLASS                    |
   #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+

   ## QNAME
   # Advance array position 
   ptr=12
   int_array=( ${int_array[@]:$ptr} )

   dns.implode.string "${int_array[@]}"
   fqdn="$REPLY"
   q_name="$REPLY"
   echo ptr: $ptr
   ptr+=$COUNT
   echo dns.reply: FQDN "'$fqdn'" " " 

   local q_label=""
   buf.dns_implode_string q_label
   echo q_label "$q_label"


   # Advance array position 
   int_array=( ${int_array[@]:$count} )

   ## QTYPE, QCLASS
															echo ptr: $ptr
   q_type=$((  0x${array[@]:$(( ( ptr      ) * 2)):4} ));	echo ptr: $ptr
   q_class=$(( 0x${array[@]:$(( ( ptr += 2 ) * 2)):4} )); 	echo ptr: $ptr
   ptr+=2; 													echo ptr: $ptr

   buf.NextWord q_typ
   buf.NextWord q_cla
   set | egrep '^(q_|h_)'
#   declare -p q_name q_type q_class ptr
   exit 1


	# 00: 4feb 8180 0001 0011 0000 0004 0667 6f6f  O............goo
	# 10: 676c 6503 636f 6d00 00ff 0001 c00c 0010  gle.com.........
	# 20: 0001 0000 079f 004c 4b76 3d73 7066 3120  .......LKv=spf1 
	# 30: 696e 636c 7564 653a 5f73 7066 2e67 6f6f  include:_spf.goo
	# 40: 676c 652e 636f 6d20 6970 343a 3231 362e  gle.com ip4:216.
	# 50: 3733 2e39 332e 3730 2f33 3120 6970 343a  73.93.70/31 ip4:
	# 60: 3231 362e 3733 2e39 332e 3732 2f33 3120  216.73.93.72/31 
	# 70: 7e61 6c6c c00c 0001 0001 0000 0073 0004  ~all.........s..
	# 80: 4a7d ed09 c00c 0001 0001 0000 0073 0004  J}...........s..
	# 90: 4a7d ed0e c00c 0001 0001 0000 0073 0004  J}...........s..
	# a0: 4a7d ed02 c00c 0001 0001 0000 0073 0004  J}...........s..
	# b0: 4a7d ed07 c00c 0001 0001 0000 0073 0004  J}...........s..
	# c0: 4a7d ed03 c00c 0001 0001 0000 0073 0004  J}...........s..
	# d0: 4a7d ed06 c00c 0001 0001 0000 0073 0004  J}...........s..
	# e0: 4a7d ed04 c00c 0001 0001 0000 0073 0004  J}...........s..
	# f0: 4a7d ed08 c00c 0001 0001 0000 0073 0004  J}...........s..
	# 100: 4a7d ed01 c00c 0001 0001 0000 0073 0004  J}...........s..
	# 110: 4a7d ed00 c00c 0001 0001 0000 0073 0004  J}...........s..
	# 120: 4a7d ed05 c00c 0002 0001 0003 c7b1 0006  J}..............
	# 130: 036e 7331 c00c c00c 0002 0001 0003 c7b1  .ns1............
	# 140: 0006 036e 7333 c00c c00c 0002 0001 0003  ...ns3..........
	# 150: c7b1 0006 036e 7334 c00c c00c 0002 0001  .....ns4........
	# 160: 0003 c7b1 0006 036e 7332 c00c c00c 001c  .......ns2......
	# 170: 0001 0000 0039 0010 2404 6800 4006 0800  .....9..$.h.@...
	# 180: 0000 0000 0000 1009 c142 0001 0001 0002  .........B......
	# 190: c689 0004 d8ef 240a c154 0001 0001 0002  ......$..T......
	# 1a0: cc4d 0004 d8ef 260a c166 0001 0001 0002  .M....&..f......
	# 1b0: cb6b 0004 d8ef 220a c130 0001 0001 0002  .k...."..0......
	# 1c0: c441 0004 d8ef 200a                      .A.... .

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

	  echo -e "_type: $_type"

	  case $_type in
		 1 )
			array_shift o1 int_array
			array_shift o2 int_array
			array_shift o3 int_array
			array_shift o4 int_array

			ip4="$o1.$o2.$o3.$o4"
			echo -e "\t$ip4"
			;;
		 6 )
			;;
		 16 )
			array_shift x int_array
			(( x )) || break
			part=
			while (( x-- ))
			do
			   array_shift c int_array
			   printf -v ch \\$(printf '%03o' $c)
			   part+=$ch
			done
			echo $part
			;;
		 12 )
			fqdn=
			while true
			do
			   echo $x
			   array_shift x int_array
			   (( x )) || break
			   part=
			   while (( x-- ))
			   do
				  array_shift c int_array
				  printf -v ch \\$(printf '%03o' $c)
				  part+=$ch
			   done
			   echo $part
			   fqdn+="$part."
			done
			fqdn=${fqdn%.}
			echo $fqdn
			;;
		 * )
	  esac


	  echo "stuff left:"
	  echo "${int_array[@]}"

	  break
   done
}

NAMESERVERS=( 192.168.1.238 203.12.176.130 61.9.197.116 8.8.8.8 61.9.211.1 )
cat spam_check.ips | 
while read -r 
do
	# explode "." "$REPLY"
	# rhost="${EXPLODED[3]}.${EXPLODED[2]}.${EXPLODED[1]}.${EXPLODED[0]}.in-addr.arpa."
	rhost=$REPLY

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
	break
done
exit
# vim: set ts=4 sts=0 sw=3 noet:
