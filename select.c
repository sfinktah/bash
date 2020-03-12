#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/select.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>


// Remove define in product, we may use stderr as a 3rd socket input
#define DEBUG_PRINTF
#ifndef DPRINTF
#ifdef DEBUG_PRINTF
#define DPRINTF(format, args...)  \
	fprintf (stderr, format , ## args) 
#else
#define DPRINTF(format, args...)  \
	nak (format , ## args)
#endif
#endif

#define ERROR(format, args...)  \
	( fprintf (stderr, format , ## args), printf ("-1\n"), 1 ) 

int fok(int fd)
{
	return fcntl(fd, F_GETFL) != -1;
}

     
/*
int getoptexample (int argc, char **argv)
{
	int aflag = 0;
	int bflag = 0;
	char *cvalue = NULL;
	int index;
	int c;

	opterr = 0;

	while ((c = getopt (argc, argv, "t:")) != -1)
		switch (c)
		{
			case 'a':
				aflag = 1;
				break;
			case 'b':
				bflag = 1;
				break;
			case 't':
				cvalue = atoi(optarg);
				break;
			case '?':
				if (optopt == 't')
					fprintf (stderr, "Option -%c requires an argument.\n", optopt);
				else if (isprint (optopt))
					fprintf (stderr, "Unknown option `-%c'.\n", optopt);
				else
					fprintf (stderr,
							"Unknown option character `\\x%x'.\n",
							optopt);
				return 1;
			default:
				abort ();
		}

	for (index = optind; index < argc; index++)
		printf ("Non-option argument %s\n", argv[index]);
	return 0;
}
*/

int main(int argc, char **argv) {
	int i, n, max = 0;
	struct timeval tv;
	fd_set readfds;

	if (argc < 2) {
		printf("usage: %s [-t seconds] fd1 [ fd2 [ fd3 ... ]]\n", argv[0]);
		printf("returns list of fd await read, space seprated.\n");
		exit(1);
	}

	tv.tv_sec = tv.tv_usec = 0;
	FD_ZERO(&readfds);

	for (i=1; i<argc; i++) {
		n = atoi(argv[i]);
		if (n < 0) tv.tv_sec = n * -1;
		else if (fok(n)) FD_SET(n, &readfds);
		else return ERROR("Invalid file descriptor: %d\n", n);
		max = (n > max) ? n : max;
	}
		
	switch (n = select(max+1, &readfds, NULL, NULL, tv.tv_sec ? &tv : NULL)) {
		case -1: return ERROR("select(): %d\n", errno);
		case  0: return 1;
	}

	for (max=n, i=1; i<argc; i++) {
		n = atoi(argv[i]);
		if (n < 0) continue;
		if (FD_ISSET(n, &readfds)) {
			printf("%d%s", n, --max ? " " : "");
		}
	}
	printf("\n");
	return 0;
}
