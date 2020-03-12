#!/usr/bin/env bash
. include array exceptions

__CATCH_exception()
{
	echo
	echo Exception: "$*"
	echo
	exit 1
}

array.new ports

ports[echo]="Echo"
ports[discard]="Discard"
ports[daytime]="Daytime (RFC 867)"
ports[chargen]="Character Generator"
ports[ftp-data]="File Transfer [Default Data]"
ports[ftp]="File Transfer [Control]"
ports[ssh]="SSH Remote Login Protocol"
ports[telnet]="Telnet"
ports[smtp]="Simple Mail Transfer"
ports.set squid "Squid Proxy"

echo "The list has `ports.length` entries."
echo "The full name for 'ssh' is `ports.get ssh`"
ports.find "Telnet" ports && echo "There is an entry ($KEY) for Telnet"
array.array_search "Telnet" ports && echo "There is an entry ($KEY) for Gopher"
echo 
echo "These are all the known ports:"
echo

ports.foreach
do
	printf "%10s %s\n" $key "${ports[$key]}"
done

array.keys ports
for key in "${KEYS[@]}"
do
	printf "%10s %s\n" $key "${ports[$key]}"
done

declare -p ports


: <<'OUTPUT'

The list has 9 entries.
The full name for 'ssh' is SSH Remote Login Protocol

These are all the known ports:

   chargen Character Generator
   daytime Daytime (RFC 867)
    telnet Telnet
      echo Echo
  ftp-data File Transfer [Default Data]
       ftp File Transfer [Control]
       ssh SSH Remote Login Protocol
      smtp Simple Mail Transfer
   discard Discard


OUTPUT



## Wierd things
: <<'WIERD'

root@proxy ~/dev/gsm/bash $ declare -a list=(cat dog fish)
																+ list=(cat dog fish)
																+ declare -a list
root@proxy ~/dev/gsm/bash $ declare -p list
																+ declare -p list
declare -a list='([0]="cat" [1]="dog" [2]="fish")'
root@proxy ~/dev/gsm/bash $ declare -a list='([0]="cat" [1]="dog" [2]="fish")'
																+ declare -a 'list=([0]="cat" [1]="dog" [2]="fish")'
root@proxy ~/dev/gsm/bash $ declare -p list
																+ declare -p list
declare -a list='([0]="cat" [1]="dog" [2]="fish")'
root@proxy ~/dev/gsm/bash $ 

root@proxy ~/dev/gsm/bash $ declare -a list='("cat" "dog" "fish")'
																+ declare -a 'list=("cat" "dog" "fish")'
root@proxy ~/dev/gsm/bash $ declare -p list
																+ declare -p list
declare -a list='([0]="cat" [1]="dog" [2]="fish")'
root@proxy ~/dev/gsm/bash $ declare -a list='(cat dog fish)'
																+ declare -a 'list=(cat dog fish)'
root@proxy ~/dev/gsm/bash $ declare -a 'list=(cat dog fish)'
																+ declare -a 'list=(cat dog fish)'
root@proxy ~/dev/gsm/bash $ declare -p list
																+ declare -p list
declare -a list='([0]="cat" [1]="dog" [2]="fish")'
root@proxy ~/dev/gsm/bash $ 

WIERD

