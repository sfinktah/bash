#!/usr/bin/env bash

chr() {
	printf \\$(printf '%03o' $1)
}

in=$'CR\rLF\n<'
test1=$in
test2="${in}"
echo -n "$test1" | xxd
echo -n "$test2" | xxd
