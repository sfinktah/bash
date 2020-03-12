#!/usr/bin/env bash
. include fds

PPLNET_HOST=spanky.nt4.com
PPLNET_PORT=59596

socket.pplnet.connect() {
   local argc=$#
   local proxy=$1
   local host=$2
   local port=$3
   if [ -n "$4" ]; then
      FD=$4
   else
      open /dev/tcp/$PPLNET_HOST/$PPLNET_PORT rw                     || return
   fi
   write $FD "howdy|$proxy|$host|$port^"                             || return
   return 
}

socket.pplnet.connect 27.131.100.100 $PPLNET_HOST $PPLNET_PORT       || { echo failed 1 && exit 1; }
socket.pplnet.connect 27.131.100.101 $PPLNET_HOST $PPLNET_PORT $FD   || { echo failed 2 && exit 1; }
socket.pplnet.connect 27.131.100.102 $PPLNET_HOST $PPLNET_PORT $FD   || { echo failed 3 && exit 1; }
socket.pplnet.connect 27.131.100.103 my.ipspace.com 80         $FD   || { echo failed 4 && exit 1; }
writeline $FD "GET / HTTP/1.1" 
writeline $FD "Host: my.ipspace.com" 
writeline $FD ""
while fgets $FD; do
   echo $REPLY
done
close $FD

HTTP/1.1 200 OK
Date: Fri, 29 Jun 2012 05:33:27 GMT
Server: Apache/2.2.17 (EL)
X-Powered-By: PHP/5.2.11
Last-Modified: Fri, 29 Jun 2012 05:33:27 GMT
Cache-Control: no-store, no-cache, must-revalidate
Cache-Control: post-check=0, pre-check=0
Pragma: no-cache
Vary: Accept-Encoding
Content-Length: 15
Content-Type: text/html; charset=UTF-8

27.131.100.103
