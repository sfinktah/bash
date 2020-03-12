. upvars.inc.sh

shopt -s expand_aliases
alias get_array_by_ref='e="$( declare -p ${1} )"; eval "declare -A E=${e#*=}"'
alias getarg='arg.get "${1}"'

arg.get()
{
	echo getting "$1" into "$2"
	local "$2" && upvar $2 "$1"
}

array.t() 
{
	get_array_by_ref
  	declare -p E
}

array.in_array()
{
	getarg needle && shift													 # echo needle: $needle
	get_array_by_ref
	for value in "${E[@]}"; do
		[[ $value == $needle ]] && return 0
	done
	return 1
}

array.array_search()
{
	getarg needle && shift
	get_array_by_ref
	for key in "${!E[@]}"; do
		[[ ${E[$key]} == $needle ]] && return 0
	done
	return 1
}


declare -A A='([a]="1" [b]="2" [c]="3" )'
echo -n original declaration:; declare -p A
echo -n running function tst: 
array.t A

array.in_array pig A && echo found || echo not found
array.in_array 2 A && echo found || echo not found
array.array_search 2 A && echo found in position $key || echo not found
array.array_search 2 A && unset A[$key]
declare -p A



# vim: set ts=3 sts=64 sw=3 noet:
