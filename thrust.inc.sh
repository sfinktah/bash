#!/usr/bin/env bash
####
####                                                        
##     __  __  Thrust into BASH  __ 
##    / /_/ /_  _______  _______/ /_
##   / __/ __ \/ ___/ / / / ___/ __/
##  / /_/ / / / /  / /_/ (__  ) /_  
##  \__/_/ /_/_/   \__,_/____/\__/  
##  
## 
## Copyright (C) 2013 - Anonymous
##
## This program is free software; you can redistribute it and/or
## modify it under the terms of the GNU General Public License
## as published by the Free Software Foundation; either version 2
## of the License, or (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
##
####
####

BASEDIR=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)
# . ${BASEDIR}/includer.inc.sh upvars classes
. ${BASEDIR}/include upvars exceptions misc


function mydate
{
	/usr/bin/env date
}

function blah
{
	REPLY=blue
}

## eg: thrust stdout from date into myvar
## eg: thrust REPLY from read into line
function thrust
{
	local __function=$3
	local __src=$1
	local __dst=$5

	test -z "$__dst" && throw "Not enough arguments"
	function_exists "$__function" || which "$__function" || throw "Function does not exist"

	case $__src in
		stdout )
			tmpfile=$TMPDIR/tmp.thrust.$$	# Could speed this up using /dev/shm (if it exists)
			$__function > $tmpfile 2>/dev/null
			# mapfile output < $tmpfile	# For multiple lines that will produce arrays
			read -r output < $tmpfile		# For regular output
			rm $tmpfile
			local "$__dst" && upvar $__dst "$output"

			;;
		* )
			echo running function $__function
			$__function
			echo "variable ${__src} is '${!__src}'"
			local "$__dst" && upvar $__dst "${!__src}"
			;;

	esac

}

function thrust.test
{
	thrust stdout from date into myvar
	thrust stdout from mydate into myvar2
	thrust REPLY from blah into myvar3

	declare -p myvar myvar2 myvar3
}

# thrust.test
