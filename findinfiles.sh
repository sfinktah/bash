#!/usr/bin/env bash

. ~root/proxies/includer.inc.sh argparser


function term_error
{
	echo "$@" > /dev/stderr
	exit 1
}

function io.readln
{
	read -r
}

function io.writeln
{
	echo "$*"
}


exclude_paths=( /Volumes /Applications /Library /System /mnt /dev /proc /sys )
exclude_regex=( "/\.backup" "/\." "^.?/(Volumes|Applications|Library|System|mnt|dev|proc|sys)" )

function files.verbose.printf
{
	printf "$@" > /dev/stderr
}

function files.find
{
	find / -xdev | egrep "$1"
}

function files.locate
{
	locate "$1" | egrep "$1$"
}

function files.search
{
	if egrep -si 'Battlestar' "$1" 
	then
		files.verbose.printf "Text found in file: %s" "$1"
	fi
}

function files.process
{
	local ex
	local len

	while io.readln
	do
		for ex in "${exclude_paths[@]}"
		do
			len=${#ex}
			[[ ${REPLY:0:$len} == $ex ]] && continue 2	# continue reading stdin
		done

		for ex in "${exclude_regex[@]}"
		do
			[[ $REPLY =~ $ex ]] && continue 2	# continue reading stdin
		done

		files.verbose.printf "%-200s\r" "${REPLY:0:200}"
		files.search "$REPLY"
	done

}

function main
{

	# Arguments with a default of 'false' do not take paramaters
	ArgParser::addArg "[h]elp"		false		"This crud"
	ArgParser::addArg "[x]dev"		false		"Stay on root device"
	ArgParser::addArg "[q]uiet"	false		"Supress output"
	ArgParser::addArg "[v]erbose"	false		"Extra output"
	ArgParser::addArg "[l]ocate"	false		"Use locate"
	ArgParser::addArg "find"		false		"Use find"
	ArgParser::addArg "list"		false		"List files (don't search within)"
	ArgParser::addArg "[f]ile"		".xml$"	"Filename(s) to search (egrep format)"
	ArgParser::addArg "[t]ext"		"makePot"	"Text to search for in files (egrep format)"

	# declare -p __arglist
	ArgParser::parse "$@"

	ArgParser::isset help && ArgParser::showArgs && exit 0

	ArgParser::isset "quiet" && echo "Quiet!" >&2
	ArgParser::isset "verbose" && echo "Verbose!" >&2

	# returns: 0 on success, 1 on failure
	ArgParser::tryAndGetArg file into find_file || term_error "No file pattern specified with --file"
	ArgParser::tryAndGetArg text into find_text || term_error "No search pattern specified with --text"
	ArgParser::isset find || ArgParser::isset locate || term_error "Neither --find or --locate specified"


	ArgParser::isset find  && {
		files.find   "$find_file" "$find_file_regex" | files.process "$find_text"
		return 0
	}

	ArgParser::isset locate && {
		files.locate "$find_file" "$find_file_regex" | files.process "$find_text"
		return 0
	}

	term_error "How did you get here?"
}


main "$0" "$@" || exit 1
