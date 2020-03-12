/*
** showip.c -- show IP addresses for a host given on the command line
*/

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <netinet/in.h>

int lazy_getaddr(char *host, char **result)
{
    struct addrinfo hints, *res, *p;
    int status;
    char ipstr[INET6_ADDRSTRLEN];

    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_INET; // AF_INET or AF_INET6 to force version AF_UNSPEC for any
    hints.ai_socktype = SOCK_STREAM;

    if ((status = getaddrinfo(host, NULL, &hints, &res)) != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(status));
        return 2;
    }

    // printf("IP addresses for %s:\n\n", host);

    for(p = res;p != NULL; p = p->ai_next) {
        void *addr;
        char *ipver;

        // get the pointer to the address itself,
        // different fields in IPv4 and IPv6:
		  if (p->ai_family == AF_INET) { // IPv4
			  struct sockaddr_in *ipv4 = (struct sockaddr_in *)p->ai_addr;
			  addr = &(ipv4->sin_addr);
			  ipver = "IPv4";
        } else { // IPv6
			  continue;
			  struct sockaddr_in6 *ipv6 = (struct sockaddr_in6 *)p->ai_addr;
			  addr = &(ipv6->sin6_addr);
			  ipver = "IPv6";
        }

        // convert the IP to a string and print it:
        inet_ntop(p->ai_family, addr, ipstr, sizeof ipstr);
		  *result = strdup(ipstr);
		  freeaddrinfo(res); // free the linked list
		  return 0;
        // printf("%s: %s\n", ipver, ipstr);
    }

    freeaddrinfo(res); // free the linked list

	 fprintf(stderr, "This point probably shouldn't be reached: %s:%d\n", __FILE__, __LINE__);
    return 3; // THis point probably shouldn't be reached
}
