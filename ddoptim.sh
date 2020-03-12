#!/usr/bin/env bash

trap 'sigint' INT

function sigint
{
	term_error SIGINT
}
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


function verbose.printf
{
	printf "$@" > /dev/stderr
}

function main
{

	# Arguments with a default of 'false' do not take paramaters
	ArgParser::addArg "if"			"/dev/sda"		"Drive or Partition to test"
	ArgParser::addArg "[h]elp"		false		"This crus"

	# declare -p __arglist
	ArgParser::parse "$@"

	ArgParser::isset help && ArgParser::showArgs && exit 0

	# returns: 0 on success, 1 on failure
	ArgParser::tryAndGetArg if into disk || term_error "No disk specified with --if"

	start=1
	current=1
	stop=65536
	size=65536
	size=10240
	stop=$size

	while (( current < stop ))
	do
		(( count = size / current ))
		echo -n "$current k: "
		dd if=$disk of=/dev/null bs=${current}k count=$count

		(( current *= 2 ))

		# 419430400 bytes (419 MB) copied, 11.8132 s, 35.5 MB/s
	done

}


main "$0" "$@" || exit 1
