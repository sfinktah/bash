#!/usr/bin/env bash
function shutup_cd
{
	builtin cd "$@" > /dev/null 2>/dev/null
}

function realpath
{
	(
		IFS=/
		a=( $@ )																	 # Explode the individual components of the path
		for d in "${a[@]}"
		do
			[[ "$d" == "" ]] && d=/											 # Actual / in the path is exploded into empty entry
			[[ ! -e "$d" ]] && { echo "Path subcomponent does not exist: '$d'" >&2; break; }
			[[ -d "$d" ]] && {
				# echo -n dir:
				shutup_cd "$d"															 # Changing directories resolves things like a//b 
				l=$( readlink "$PWD" ) && shutup_cd "$l"
				# echo $l
				# echo "$PWD"
				f=0
			} || {
				# echo -n file:
				l=$( readlink "$d" ) && shutup_cd "$( dirname "$l" )"
				f=1
				# echo "$PWD/$d"
			}
		done
		(( f )) && echo "$PWD/$d" || echo "$PWD"
	)
}
	

function cdtrack
{
	(( ! $# )) && cd && return
	local p
	\cd "$@"
	# builtin history -s _rcd \""$( realpath "$PWD" )"\"
	if [[ $PWD != "/root" ]]; then
		echo "$( realpath "$PWD" )" >> ~/.cdhistory
	fi
}
declare -x realpath
declare -x cdtrack
alias cd=cdtrack
alias cdh=". cdh.sh"
# vim: set ts=3 sts=64 sw=3 noet:
