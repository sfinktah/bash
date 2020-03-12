#!./socketpair /usr/bin/env bash
# We are now in a BASH script with a pair of linked sockets,
# $DUP1 and $DUP2

## Background job ## Received data on DUP1
(
	while read -r -u $DUP1
	do
		echo "Received: $REPLY"
	done 
) &


## Foreground task ## Sends data to DUP2
counter=0
while true
do
	echo Test $(( counter++ )) >&$DUP2
	sleep 1
done


## Source code for simple 'socketpair' binary
## Compile with "cc -o socketpair socketpair.c"
cat <<'SOURCE'
/** 
* @file socketpair.c
* @author christopher anserson
* @date 2012-04-28
*/
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/socket.h>

char* custom_itoa(int i) {
	  static char output[24];
	 return sprintf(output, "%d", i), output;
}

int main(int argc, char **argv) {
	  int sv[2]; /* the pair of socket descriptors */

	  if (socketpair(AF_UNIX, SOCK_STREAM, 0, sv) == -1) {
			perror("socketpair");
			exit(1);
	  }
	 setenv("DUP1", custom_itoa(sv[0]), 1);
	 setenv("DUP2", custom_itoa(sv[1]), 1);

	 /* now exec whatever script needed these paired sockets */
	 execv(argv[1], &argv[1]);
	  return 0;
}
SOURCE
