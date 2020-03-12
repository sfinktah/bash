#!/usr/bin/env bash

# Test to record (and seperate) pre-existing environment variables from variables declared in script.

declare -A EXISTING_ENV
record_env() {
	for i in _ {a..z} {A..Z}; do
		for var in `eval echo "\\${!$i@}"`; do
			EXISTING_ENV[$var]=$var
			# you can test if $var matches some criteria and put it in the file or ignore
		done 
	done 
}

was_in_env() {
	[ -n "${EXISTING_ENV[$1]}" ] && return 0
	return 1
}

list_new_env() {
	for i in _ {a..z} {A..Z}; do
		for var in `eval echo "\\${!$i@}"`; do
			was_in_env "$var" || echo "$var"
		done 
	done  
}

# POO=POOP
# record_env
# export POOP
# was_in_env POO || echo new poe
# was_in_env VIM || echo new vim
# new=one
# newer=two
# AANOTHER=one
# another=one
# export another
# list_new_env
# echo "${!A*}"
