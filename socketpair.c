/** 
* @file socketpair.c
* @brief adapted from beej's ipc guide
* @author christopher anserson
* @date 2012-04-28
*/
#include <stdio.h>
#include <stdlib.h>
// #include <ctype.h>
#include <errno.h>
//  #include <unistd.h>
// #include <sys/types.h>
#include <sys/socket.h>

char* custom_itoa(int i)
{
    static char output[24];  // 64-bit MAX_INT is 20 digits
	 sprintf(output, "%d", i);
	 return output;
}

int main(int argc, char **argv)
{
    int sv[2]; /* the pair of socket descriptors */

    if (socketpair(AF_UNIX, SOCK_STREAM, 0, sv) == -1) {
        perror("socketpair");
        exit(1);
    }
	 setenv("DUP1", custom_itoa(sv[0]), 1);
	 setenv("DUP2", custom_itoa(sv[1]), 1);

	 // now exec whatever script needed these paired sockets
	 execv(argv[1], &argv[1]);
	 

#ifdef ORIGINAL_CODE
    char buf; /* for data exchange between processes */
    if (!fork()) {  /* child */
        read(sv[1], &buf, 1);
        printf("child: read '%c'\n", buf);
        buf = toupper(buf);  /* make it uppercase */
        write(sv[1], &buf, 1);
        printf("child: sent '%c'\n", buf);

    } else { /* parent */
        write(sv[0], "b", 1);
        printf("parent: sent 'b'\n");
        read(sv[0], &buf, 1);
        printf("parent: read '%c'\n", buf);
        wait(NULL); /* wait for child to die */
    }
#endif
    return 0;
}
