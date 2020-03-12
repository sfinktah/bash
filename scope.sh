#!/bin/bash

# Scope tests.

a() {
	R=a
}

b() {
	R=b
}
	
c() {
	echo function c
	R=c
}

pipe() {
	cat <&0 >&1
}

a
b > /dev/null
c >( /dev/null )
cat <&63
echo $R
