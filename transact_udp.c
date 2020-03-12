/* Adapted from:
 * transact_udp.c -- a datagram "client" demo
 * http://www.beej.us/guide/bgnet/output/html/singlepage/bgnet.html#datagram
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

#define MAXBUFLEN 1024


// get sockaddr, IPv4 or IPv6:
void *get_in_addr(struct sockaddr *sa)
{
    if (sa->sa_family == AF_INET) {
        return &(((struct sockaddr_in*)sa)->sin_addr);
    }

    return &(((struct sockaddr_in6*)sa)->sin6_addr);
}

int transact_udp(const char *host, const char *port, char *buffer, size_t *length, const size_t max_length)
{
    char s[INET6_ADDRSTRLEN];
    int numbytes;
	 int flags = 0;
    int rv;
    int sockfd;
    socklen_t addr_len;
    struct addrinfo hints, *servinfo, *p;
    struct sockaddr_storage their_addr;

    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_DGRAM;

    if ((rv = getaddrinfo(host, port, &hints, &servinfo)) != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(rv));
        return -1;
    }

    // loop through all the results and make a socket
    for(p = servinfo; p != NULL; p = p->ai_next) {
        if ((sockfd = socket(p->ai_family, p->ai_socktype,
                p->ai_protocol)) == -1) {
            perror("transact_udp: socket");
            continue;
        }
        break;
    }

	 // printf(stderr, "host: %s port: %s\n", host, port);
    if (p == NULL) {
        fprintf(stderr, "transact_udp: failed to bind socket\n");
		  freeaddrinfo(servinfo);
		  close(sockfd);
		  return -1;
    }

	 if ((numbytes = sendto(sockfd, buffer, *length, flags, 
					 p->ai_addr, p->ai_addrlen)) == -1) {
		 perror("transact_udp: sendto");
		 fprintf(stderr, "sockfd: %d\n", sockfd);

		 freeaddrinfo(servinfo);
		 close(sockfd);
		 return -1;
	 }

   //  printf("transact_udp: sent %d bytes to %s\n", numbytes, host);

    addr_len = sizeof their_addr;
	 // while (1) {
    if ((numbytes = recvfrom(sockfd, buffer, max_length - 1 , 0,
        (struct sockaddr *)&their_addr, &addr_len)) == -1) {
        perror("recvfrom");

		  freeaddrinfo(servinfo);
		  close(sockfd);
		  return -1;
    }

	 *length = numbytes;

   // printf("listener: got packet from %s\n", inet_ntop(their_addr.ss_family, get_in_addr((struct sockaddr *)&their_addr), s, sizeof s));
   // printf("listener: packet is %d bytes long\n", numbytes);
    buffer[numbytes] = '\0';	// we can remove this for binary communications
    // printf("listener: packet contains \"%s\"\n", buf);
	 // }

    close(sockfd);
    freeaddrinfo(servinfo);

	 // close(sockfd);

	 return 0;
    // return sockfd;
}
