#!/usr/bin/env bash

url=http://bits.wikimedia.org/geoiplookup
regex="inet addr:([0-9.]+)"
# SED solution by Pod
ifconfig -a | sed '/^eth0/ {N; s/\n/MATCH/g}' | grep eth1 | 
while read -r line; do
 [[ $line =~ $regex ]] && {
  ip=${BASH_REMATCH[1]}

  curl -s --interface $ip --max-time 10 $url
  echo
 }
done < <( ifconfig -a | sed '/^eth0/ {N; s/\n/MATCH/g}' | grep MATCH ) # SED solution by Pod

url=http://bits.wikimedia.org/geoiplookup
url2=http://autoupdate.geo.opera.com/geolocation/
ifconfig -a | grep eth0 | sed 's/ .*//' |
while read -r line; do
  curl -s -m 10 --interface $line $url $url2 || echo -n "Fail = {\"ip\":\"$line\"}"
  echo
done


while read -r IP
do
	echo $( curl -s -m 10 --proxy-user pplproxy:$IP --socks5 controller.stinkyrabbit.com:9596 http://bits.wikimedia.org/geoiplookup ) | tee -a ip.log
done
