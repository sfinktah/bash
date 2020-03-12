#!/bin/bash

get_delay() {
	TIMESERVER="$1"
	TIMES="${2:-20}"
	TIMEPORT=123
	TIME1970=2208988800      # Thanks to F.Lundh 0x 0xD2AA5F0
	exec 6<>/dev/udp/$TIMESERVER/$TIMEPORT &&
	echo -en "\x1b\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" >&6 \
		|| echo "error writing to $TIMESERVER $TIMEPORT"
		read -u 6 -n 1 -t 2 || { echo "*"; return; }

	for (( n=0; n<TIMES; n++ )); do
		echo -en "\x1b\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" >&6 \
		|| echo "error writing to $TIMESERVER $TIMEPORT"
		REPLY="$(dd bs=50 count=1 <&6 | dd skip=32 bs=1 count=16 | xxd -p)"
		echo -n "."

		seconds="${REPLY:0:8}"
		secondsf="${REPLY:8:8}"

		sec=0x$( echo -n "$seconds" )
		secf=0x$( echo -n "$secondsf" )
		(( i_seconds = $sec - TIME1970 ))
		(( i_secondsf = ( 1000 * $secf / 0xffffffff ) ))
		# echo i_seconds: $i_seconds.$i_secondsf
		s[$n]=$i_seconds
		m[$n]=$i_secondsf
	done
	echo 

	# declare -p s m

	for (( m=1; m<TIMES-1; m++)); do
		(( n = m + 1 ))
		# (( d[$m] = ( 1000 * ( s[$n] - s[$m] ) ) + $m[$n] - $m[$m] ))
		(( d[m] = ( 1000 * ( s[n] - s[m] ) ) + m[n] - m[m] ))
		printf "%s\n" "${d[$m]} ms"
	done
} 2>/dev/null

TIMESERVERS=( {1..3}.{north-america,ca,us}.pool.ntp.org {0..3}.europe.pool.ntp.org {0..3}.asia.pool.ntp.org {0..3}.oceania.pool.ntp.org south-america.pool.ntp.org africa.pool.ntp.org )
EUROPE=( at.pool.ntp.org ch.pool.ntp.org de.pool.ntp.org dk.pool.ntp.org es.pool.ntp.org fr.pool.ntp.org it.pool.ntp.org lu.pool.ntp.org nl.pool.ntp.org no.pool.ntp.org pl.pool.ntp.org se.pool.ntp.org si.pool.ntp.org uk.pool.ntp.org fi.pool.ntp.org ie.pool.ntp.org ru.pool.ntp.org be.pool.ntp.org pt.pool.ntp.org gr.pool.ntp.org hu.pool.ntp.org bg.pool.ntp.org ro.pool.ntp.org cz.pool.ntp.org yu.pool.ntp.org ee.pool.ntp.org by.pool.ntp.org sk.pool.ntp.org ua.pool.ntp.org lt.pool.ntp.org mk.pool.ntp.org md.pool.ntp.org lv.pool.ntp.org hr.pool.ntp.org rs.pool.ntp.org ba.pool.ntp.org am.pool.ntp.org )
ASIA=( sh.pool.ntp.org ph.pool.ntp.org  tr.pool.ntp.org in.pool.ntp.org hk.pool.ntp.org ae.pool.ntp.org jp.pool.ntp.org bd.pool.ntp.org il.pool.ntp.org kr.pool.ntp.org th.pool.ntp.org ir.pool.ntp.org tw.pool.ntp.org cn.pool.ntp.org id.pool.ntp.org vn.pool.ntp.org pk.pool.ntp.org om.pool.ntp.org uz.pool.ntp.org lk.pool.ntp.org kg.pool.ntp.org kh.pool.ntp.org qa.pool.ntp.org sa.pool.ntp.org iq.pool.ntp.org kz.pool.ntp.org my.pool.ntp.org )

# declare -p TIMESERVERS
for zone in "${TIMESERVERS[@]}"; do
	echo -n $zone:
	get_delay "$zone" 5
done
for zone in "${ASIA[@]}"; do
	echo $zone:
	get_delay "$zone" 5
done
exit

struct ntp_packet
{
  0	unsigned char mode : 3;
  1	unsigned char vn : 3;
  2	unsigned char li : 2;
  3	unsigned char stratum;
  4	char poll;
  5	char precision;
  6-9	unsigned long root_delay;
  10	unsigned long root_dispersion;
  14	unsigned long reference_identifier;
  18	unsigned long reference_timestamp_secs;
  22	unsigned long reference_timestamp_fraq;
  26	unsigned long originate_timestamp_secs;
  30	unsigned long originate_timestamp_fraq;
  34	unsigned long receive_timestamp_seqs;
  38	unsigned long receive_timestamp_fraq;
  42	unsigned long transmit_timestamp_secs;
  46	unsigned long transmit_timestamp_fraq;
};

