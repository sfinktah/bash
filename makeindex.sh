#!/usr/bin/env bash

upvar() {
    if unset -v "$1"; then           # Unset & validate varname
        if (( $# == 2 )); then
            eval $1=\"\$2\"          # Return single value
        else
            eval $1=\(\"\${@:2}\"\)  # Return array
        fi
    fi
}


function io.readln
{
	read -r
}

function io.writeln
{
	echo "$*" >> index.html
}


# {{{
function basename
{
	local __rv="${1##*/}"
	local "$3" && upvar $3 "$__rv"
}

function dirname
{
	local __rv="${1%/*}"
	local "$3" && upvar $3 "$__rv"
}

function extension
{
	local __rv="${1##*.}"
	local "$3" && upvar $3 "$__rv"
}

function noextension
{
	local __rv="${1%.*}"
	local "$3" && upvar $3 "$__rv"
}

function is_jpeg_ext
{
	local __rv=1
	shopt -s nocasematch
	[[ $1 == jpg ]] && __rv=0
	shopt -u nocasematch
	return $__rv
}
# }}}


function main
{
	find . -type d -maxdepth 1 |
	while io.readln
	do
		echo "Processing: '$REPLY'..."
		fn="${REPLY}"
		dirname "$fn" into dn
		basename "$fn" into bn
		extension "$bn" into ext
		noextension "$bn" into noext

		[[ $bn == "." ]] && continue

		io.writeln '<div class="directory line"><div class="name"><a href="'"$bn"'/">'"$bn"'</a></div></div>'
	done
}

main "$@"
