#!/usr/bin/env bash
clear

OIFS=$IFS
echo -n Default IFS: 
echo -n "$IFS" | xxd
# Default IFS:0000000: 2009 0a                                   ..

echo -n Abitary IFS:
IFS=$'\x0a'
echo -n "$IFS" | xxd

echo -n unset IFS:
unset IFS
echo -n "$IFS" | xxd
echo

echo -n set IFS to default:
IFS=$'\x20\x09\x0a'
echo -n "$IFS" | xxd

IFS=" "
echo -n set IFS to old value unescaped:
IFS=$OIFS
echo -n "$IFS" | xxd
