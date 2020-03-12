#!/usr/bin/env bash
declare -A fontlist
while read -r LINE
do
	name=$( mdls -raw -name com_apple_ats_name_full "$LINE" | head -n 2 | tail -n 1 )
	name=${name#*\"}
	name=${name%\"*}
	echo "$name: '$LINE'"
	fontlist[$name]=$LINE
done < <( find ~/Library/Fonts /Library/Fonts /Fonts -type f -name '*.otf' )
declare -p fontlist > fontlist.inc.sh
