#!/usr/bin/env bash

function string.monolithic.tolower
{
   local __word=$1
   local __len=${#__word}
   local __char
   local __octal
   local __decimal
   local __result

   for (( i=0; i<__len; i++ ))
   do
      __char=${__word:$i:1}
      case "$__char" in
         [A-Z] )
            printf -v __decimal '%d' "'$__char"
            printf -v __octal '%03o' $(( $__decimal ^ 0x20 ))
            printf -v __char \\$__octal
            ;;
      esac
      __result+="$__char"
   done
   REPLY="$__result"
}
fqdn="cyruslesser.com"
type="MX"

# Check WHOIS record for nameservers (far from guaranteed)
# whois_ns=$( whois "$fqdn" | grep "Name Server: " | sed 's/Name Server: //' )
whois_ns=$( cat /tmp/whois.txt | grep "Name Server: " | sed 's/ *Name Server: //' | sort -u )
string.monolithic.tolower "$whois_ns"
whois_nsa=($REPLY)
declare -p whois_nsa

for ns in "${whois_nsa[@]}"; do
	# echo "$ns:"
	echo dig +short "$type" "$fqdn" "@$ns"
	dig +short "$type" "$fqdn" "@$ns"
	echo 
done
