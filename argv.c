main(int argc, char *argv[]) {
	char **p;

	for ( p=argv; *p && **p; p++ ) {
		printf( "Argument: %s\n", *p);
	}
}
