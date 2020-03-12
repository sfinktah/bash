#!/usr/bin/env bash

. include whiptail

function io.readln
{
	read -r
}

option_index=()

options=()
c=0
while read -r count path
do
	(( c++ ))
	options+=( "$c" )
	options+=( "$path" )
	option_index[$c]=$path
done < <( sort ~/.cdhistory | uniq -c | sort -rn )

# echo -en '\033[?1049h'
Menu.Show '([backtitle]=""
            [title]="Title"
            [question]="Please choose:")' "${options[@]}" 2> /tmp/$$ 
el=$?
# echo -en '\033[?1049l'
(( ! el )) && 
{
	read -r number < /tmp/$$
	target=${option_index[$number]}
	echo attempting to change directory to "$target"
	test -n "$target" && cd "$target" || echo "failed"
}
rm /tmp/$$

# /* vim: set ts=3 sts=0 sw=3 ft=sh noet: */
