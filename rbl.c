#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <time.h>

#include "transact_udp.h"
#include "lazy_getaddr.h"


char *rbl_ip;

// host 2.0.0.127.b.barracudacentral.org

/** Necessary only on systems without glibc **/
void *xmalloc(size_t size)
{
	register void *value = malloc(size);

	if (value == 0) {
		fprintf(stderr, "tree: virtual memory exhausted.\n");
		exit(1);
	}
	return value;
}

void *xrealloc(void *ptr, size_t size)
{
	register void *value = realloc(ptr, size);

	if (value == 0) {
		fprintf(stderr, "tree: virtual memory exhausted.\n");
		exit(1);
	}
	return value;
}

/** 
 * @brief Explode strings into array by seperator
 * 
 * @param seperator (char)
 * @param *data (will be destructed, don't pass it a const or something stupid)
 * @param *len (input: max items to explode, output: num of items exploded)
 * 
 * @return 
 */
char ** explode_mod2(char seperator, char *data, int *num)
{
	int 	numres, i, plen, seplen, max = *num;

	// Having a go at doing a memory efficient and quicker explode,
	// only character based not string based for seperator.
	// (But we'll try and keep the code ready for an update to that)
	
	int data_len = strlen(data);
	int ncount = 0;

	char **w = xmalloc(sizeof(char *) * data_len);

	/*
	for (i=0; i<max; i++) {
		array[i] = NULL;
	}
	*/

	// if (1 || *data != seperator) {	// Ideally, we should advance until we find the first non-seperated char.  But we will make the first result equal to the start of the buf memory, so it can be freed later.
		w[ncount++] = data;
	// }

	for (i=1; i<data_len && (max && ncount < max); i++) {
		if (data[i] == seperator) {
			data[i] = 0;
			w[ncount++] = (data + i + 1);
		}
	}

	w[ncount] = NULL;

	// free(buf);
	*num = ncount;
	return w;
}

void hex_dump(unsigned char *buf, int len) {
   if (buf == NULL) {
	  fprintf(stderr, "hex_dump cannot dump NULL buffer\n");
	  return;
   }
   int i, j;
   char c;
   int start = 0;
   for (i = 0; i<len; i++) {
      if (!(i % 16) || i == len) {
		 printf(" ");
		 for (j = start; j<i; j++) {
			c = buf[j];
			printf("%c", (c > 31 && c < 127) ? c : '.');
		 }

         printf("\n%04x:\t", i);

		 start = i;
      }
      printf("%02x ", buf[i]);
   }
   printf("\n");
}

void vhex(char *str, void *buf, int len) {
   return;
   printf("%s\n", str);
   hex_dump(buf, len);
}

#define MAX_REPLY_SIZE 2048
dns_reply(char *reply, int len)
{

	//
    // char *reply = calloc(1, MAX_REPLY_SIZE);
	char buf[MAX_REPLY_SIZE];
	char *p = reply, *b = buf;
	char *result = malloc(256);
	int _type, n;
	size_t wlen;

	if (len > MAX_REPLY_SIZE / 2) {
	   fprintf(stderr, "dns reply too big (%d)\n", len);
	   return -1;
	}

	*buf = 0;

	vhex("whole packet", p, len - (p - reply));

	p += 12;
	vhex("start of fqdn read", p, len - (p - reply));
	n = 0;
	while (*p) {
	   wlen = *(p++);
	   strncpy(b, p, wlen);
	   *(b + wlen) = 0;
	   // printf("[%02d] %s (%d).", n++, b, len);
	   b += wlen;
	   *(b++) = '.';
	   p += wlen;
	   vhex("\nnext fqdn read", p, len - (p - reply));
	}
	p++; // skip over the 0x00 that signified end of fqdn strings
	// printf("\nfqdn: %s\n", buf);


//   array_shift _unk int_array
//   array_shift _unk int_array
//   array_shift _unk int_array
//   array_shift _unk int_array

   // while (( ${#int_array[@]} ))

	  // 44 a4 81 80 00 01 00 03 00 00 00 00 04 61 39 35 30 03 67 69 33 06 61 6b 61 6d
	  // 61 69 03 6e 65 74 00 00 01 00 01 c0 0c 00 01 00 01 00 00 00 14 00 04 3d 09 e1
	  // 98 c0 0c 00 01 00 01 00 00 00 14 00 04 3d 09 e1 88 c0 0c 00 01 00 01 00 00 00
	  // 14 00 04 3d 09 e1 96

	  // --? --? -TYPE   CLASS   -----------TTL  RDLEN   1-- 2-- 3-- 4--
	  // 192 12  0   1   0   1   0   0   0   20  0   4   61  9   225 152
	  // 192 12  0   1   0   1   0   0   0   20  0   4   61  9   225 136
	  // 192 12  0   1   0   1   0   0   0   20  0   4   61  9   225 150

	// vhex("skip 7", p, len - (p - reply));
	p += 7;
	// vhex("type", p, len - (p - reply));
	_type = (int)*(p++);
	p += 8;
	// vhex("skiped 8", p, len - (p - reply));

   if (_type != 1) {
	  // printf("_type !=1, type = %d\n", _type);
	  return (_type > 0) ? _type : -1;
   }

   sprintf(result, "%d.%d.%d.%d", *p, *(p + 1), *(p + 2), *(p + 3));
   p += 4;

   // printf("result: %s\n", result);
   free(result);

   return 0;

}

#define MAX_QUERY_SIZE 256
char *dns_query(char *fqdn, size_t *len) {
   int i;
   int count = 0;
   char **w;
   char *query = calloc(1, MAX_QUERY_SIZE);
   char *p = query;
   static uint16_t random_header = 0;
   if (strlen(fqdn) > MAX_QUERY_SIZE / 2) {
	  fprintf(stderr, "fqdn too big (%d)\n", (int)strlen(fqdn));
	  return NULL;
   }

   random_header += (uint16_t)time(NULL);

   random_header += 31337;
   *(p++) = random_header & 0xff;
   *(p++) = (random_header >> 8) & 0xff;
   // count = sprintf(p, "\x01\x00\x00\x01\x00\x00\x00\x00\x00\x00");
   *(p++) = 0x01;
   *(p++) = 0x00;
   *(p++) = 0x00;
   *(p++) = 0x01;
   *(p++) = 0x00;
   *(p++) = 0x00;
   *(p++) = 0x00;
   *(p++) = 0x00;
   *(p++) = 0x00;
   *(p++) = 0x00;

   int items = 255;
   w = explode_mod2('.', fqdn, &items); // , &count);
   for (i=0; w[i]; i++) {
	  // printf("w[%d]: %s\n", i, w[i]);
	  *(p++) = (uint8_t) strlen(w[i]);
	  p += sprintf(p, "%s", w[i]);
   }
   free(w);

   //    query+="\x00\x00\x01\x00\x01"

   *(p++) = 0x00;
   *(p++) = 0x00;
   *(p++) = 0x01;
   *(p++) = 0x00;
   *(p++) = 0x01;

   // printf("%s:%d:\n", __FILE__, __LINE__);
   vhex("dns_query", query, p - query);
   *len = (int)(p - query);
   return query;
}


#define MAX_FQDN_SIZE 128
int rbl_check_ip(char *ip) {
   char **w;
   char fqdn[MAX_FQDN_SIZE];
   char *query = NULL;
   int count;

   if (strlen(ip) > MAX_FQDN_SIZE / 2) {
	  fprintf(stderr, "ip too long (%d)\n", (int)strlen(ip));
	  return 1;
   }

   char *str = strdup(ip);

   int items = 8;
   w = explode_mod2('.', str, &items); // , &count);
   if (items != 4) {
	  fprintf(stderr, "exploded ip had wrong number of dots ('%s', %d)\n", str, items);
	  return -1;
   }
   sprintf(fqdn, "%s.%s.%s.%s.b.barracudacentral.org", w[3], w[2], w[1], w[0]);
   // fprintf(stderr, "fqdn: %s\n", fqdn);
   free(w);
   free(str);
		 
   size_t len = MAX_FQDN_SIZE;
   char *fqdn_copy = strdup(fqdn);
   query = dns_query(fqdn, &len);
   if (!query) {
	  fprintf(stderr, "dns_query(%s, %d) return NULL\n", fqdn_copy, (int)len);
	  free(fqdn_copy);
	  exit(1);
   }

   free(fqdn_copy);
   // query will be 256 MAX_QUERY_SIZE bytes alloced
   vhex("query", query, len);

   // transact_udp(const char *host, const char *port, char *buffer, size_t *length, const size_t max_length);
   transact_udp(rbl_ip ? rbl_ip : "203.12.176.130", "53", query, &len, MAX_QUERY_SIZE);
   vhex("query", query, len);
   return dns_reply(query, len);
   // printf("%d\n", dns_reply(dns_request(fqdn), 128));
}

int rbl_init(char *_rbl_ip) {
   int i;
   // char *rbl_ip;
   if (_rbl_ip) {
	  rbl_ip = _rbl_ip;
	  printf("rbl_ip set to %s\n", rbl_ip);
   } else {
	  if (lazy_getaddr("geons01.barracudacentral.org.", &rbl_ip)) {
		 fprintf(stderr,"failed to resolve geons01.barracudacentral.org.\n");
		 exit(1);
	  }
	  printf("geons01.barracudacentral.org. resolved to %s\n", rbl_ip);
   }
   // printf("%s: %d\n", argv[i], rbl_check_ip(argv[i], rbl_ip));
}

#ifdef RBL_MAIN
int main(int argc, char **argv) {
   int i;
   rbl_init(NULL);
   printf("127.0.0.2: %d\n", rbl_check_ip("127.0.0.2"));
   for (i=1; i<argc; i++) {
	  printf("%s: %d\n", argv[i], rbl_check_ip(argv[i]));
   }
   // dns_query("2.0.0.127.b.barracudacentral.org");
}
#endif


// vim: set ts=4 sts=0 sw=3 noet:
