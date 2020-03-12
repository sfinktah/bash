#!/usr/bin/env bash

. include mktmp

# Save a function to a file
#-Could be difficult, since functions may not
#-be visible to shell script unless exported.
function savefn {
	local saveTo=~/bin/saved
	local fnName=$1
	test -n "$fnName" || return 0
	test -d "$saveTo" || mkdir -p "$saveTo"
	test -x "$saveTo" && test -w "$saveTo" || exec date +"Can't write to '$saveTo'"
	declare -F "$fnName" || exec date +"No function matching '$fnName' found"
	mktmp
	if test -f "$saveTo/$fnName.inc.sh"; then
		cat "$saveTo/$fnName.inc.sh" > "$TEMPDIR"/fn.sh
	else
		cat > "$TEMPDIR"/fn.sh <<-EOT
		# SAVEFNDOC
		# functionName="$fnName"
		# requires=()
		# shortDesc=""
		# longDesc=<<'# EOD'
		# EOD
		EOT
	fi
	declare -f "$fnName" >> "$TEMPDIR"/fn.sh
	vi "$TEMPDIR/fn.sh" && # Does VIM give errorlevels?
	mv -vf "$TEMPDIR/fn.sh" "$saveTo/$fnName.inc.sh"
	rm -rf "$TEMPDIR/.backups" "$TEMPDIR/.fn.sh.un~"
}

savefn "$1"
# vim: set ts=3 sts=3 sw=3 noet:
