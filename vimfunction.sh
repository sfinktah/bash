#!/usr/bin/env bash
. include mktmp
function vimf
{
	local fn=$1
	if declare -F "$fn"; then
		mktmp
		declare -f "$fn" > "$TEMPDIR"/function.sh
		vim "$TEMPDIR"/function.sh    &&
		echo sourcing "$TEMPDIR"/function.sh...              &&
		source "$TEMPDIR"/function.sh
		rm "$TEMPDIR"/function.sh
		rm "$TEMPDIR"/.backups/*
		rmdir "$TEMPDIR"/.backups
		rmtmp || find "$TEMPDIR"/function.sh
	fi
}
function executed {
	:
}
function sourced {
	:
}
if [[ ${BASH_SOURCE[@]} == $0 ]]; then executed; else sourced; fi
