#!/usr/bin/env bash

# Read results of `fdupes -1` (should be run with `-r` and `-n` too)
# and turn duplicate files into hard links.

IN=${1:-/dev/stdin}
while read -a files; do
	keep=()
	for file in "${files[@]}"; do
		if [[ $file =~ /\. ]]; then
			:
		else
			if test -e "$file"; then
				keep+=( "$file" )
			fi
		fi
	done
	num=${#keep[@]}
	true && 
	if [[ ${#keep[@]} > 1 ]]; then
		#  echo
		#  echo -n "$num: ${keep[0]}"
		source=${keep[0]}
		for target in "${keep[@]:1}"; do
			printf 'ln -f %q %q\n' "$source" "$target"
		done
	fi
done < $IN
