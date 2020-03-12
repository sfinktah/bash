. include classes upvars exceptions


### Some notes from upvar webpage {{{
return_array() {
    local r=(e1 e2 "e3  e4" $'e5\ne6')
    local "$1" && upvars -a${#r[@]} $1 "${r[@]}"
}

sparseup() {
	local evalString=$(declare -p $1)
	evalString=${evalString/declare -* $1=\'/$2=}
	unset -v "$2" && eval ${evalString%\'}
}
### }}}

# This array class is for dealing with -A (associative arrays) found in bash 4 and later, but required bash 4.2 for declare -g
# declare -ar BASH_VERSINFO='([0]="4" [1]="2" [2]="20" [3]="2" [4]="release" [5]="i386-apple-darwin10.8.0")'

if [[ ${BASH_VERSINFO[0]} < 4 || ${BASH_VERSINFO[1]} < 2 ]]
then
	echo This BASH library "(${BASH_SOURCE[0]})" requires BASH 4.2 or later "(maybe)" >&2
fi

shopt -s expand_aliases
alias get_array_by_ref='e="$( declare -p ${1} )"; eval "declare -A E=${e#*=}"'
alias get_indexed_array_by_ref='e="$( declare -p ${1} )"; eval "declare -a E=${e#*=}"'
alias getarg='arg.get "${1}"'
alias propget='class::getprop "${this}"'
alias propset='class::setprop "${this}"'

class::setprop()
{
	local var="__$1__$2"
	# echo setting "$1::$2" to "$3"
	# echo declare -g $var="$3"
	declare -g $var="$3"
}

class::getprop()
{
	local var="__$1__$2"
	REPLY="${!var}"
	# echo getting "$1::$2" "$REPLY"
}


arg.get()
{
	# echo arg.get "$1, $2"
	# echo getting "$1" into "$2"
	local "$2" && upvar $2 "$1"
}


# clone source dest
array.export()
{
	# arg src	# source
	local src; getarg src && shift
	
	e="$( declare -p $src )"
	e=${e#*=}
	e=${e#\'}
	e=${e%\'}
	echo "$e"
}

array.import()
{
	local arraydef; getarg arraydef && shift
	local varname; getarg varname && shift

	declare -Ag $varname="$arraydef"
}

array.length()
{
	get_array_by_ref
	echo "${#E[@]}"
}

array.get()
{
	get_array_by_ref
	echo "${E[$2]}"
}

array.keys()
{
	(( $# )) || throw exception $FUNCNAME is missing an argument
	get_array_by_ref
	KEYS=( "${!E[@]}" )
}

array._varname_iterator()
{
	VARNAME="__ARRAY__ITERATOR__KEYS__$1"
}
array.reset()
{
	scope
	$this._varname_iterator "$1"
	$this.keys "$1"
	local $VARNAME="( ${KEYS[*]} )"		# ++ local 'rhs=( alpha beta )'
	declare -a -g $VARNAME="( ${KEYS[*]} )"		# ++ local 'rhs=( alpha beta )'
}

array.each()
{
	scope

	$this.keys "$1"
	$this._varname_iterator "$1"
   
	e="$( declare -p "$VARNAME" )"; 
	eval "declare -A E=${e#*=}"
# 	get_indexed_array_by_ref $VARNAME	# XXX: is that meant to be VARNAME (no $)
	count=${#E[@]}
	(( !count )) && return 1	# Nothing left to iterate

	KEY="${E[@]:0:1}"
	upvar $VARNAME "${E[@]:1}"
	return 0

}


array.new()
{
	unset $1 || echo invalid "'$1'"
	declare -A -g $1
	eval "$1.length() {
		scope
		array.length \$this
	};"
	eval "$1.get() {
		scope
		array.get \$this \$1
	};"
	alias $1.foreach="array.reset $1; array.each $1; for key in "'"${KEYS[@]}"'
}

array.from_declare()
{
	scope
	getarg array_name && shift
	$this.new "$array_name"
	getarg declaration

	# Check if it's a full declare (declare -a blah=  .... )  or just a   ([value]... )
	if [[ $declaration =~ ^declare ]]
	then
		declaration="${declaration#*=}"
	fi

	declare -A -g $array_name=$declaration
}

array.copy.eval()
{
	local e="$( declare -p ${1} )"
	echo "declare -A $2=${e#*=}"
}

declare_type()
{
	TYPE=
	TYPE_DECLARE=
	local d
	[[ $1 =~ ^declare ]] && 
	{
		TYPE_DECLARE=1
		d="$1"
	} || 
	{
		declare -F "$1" && TYPE=F && return 
		d="$( declare -p "$1")" || TYPE= && return 1
	}
	echo "$d"
	# declare -x TZ="Australia/Melbourne"

	# declare -a a='([0]="a" [1]="b" [2]="c")'
	# declare -A A='([a]="1" )'
	# declare -ax b='([0]="a" [1]="b" [2]="c")'
	# declare -Ax B='([a]="1" )'
	# declare -- 
	# declare -Artx B='([a]="1" )'

	local _type
	local _definition
	local _declare
	# This is pure lazyness, and is probably not very efficient.
	read _declare _type _definition < <( echo "$def" )

	_type=${_type##-}		# removing silly dashes
	# for the moment, we only need to know if it's an array, Array or normal.   integers, exports, read-only etc can get bent
	[[ ${#_type} == 0  ]] && TYPE=- && return 0
	[[ $_type =~ (a|A) ]] && TYPE=${BASH_REMATCH[1]} && return 0
	
	TYPE=
	return 1
}

# not finished yet
test_array()
{
	# must use subscript when assigning associative array
	local r="$( local -A t="$1" 2>&1 )"; [[ $r == "" ]] && echo associative array
	unset t
	local -a t="$1"; echo a: $?
	unset t
	local t="$1"; echo v: $?

}

argtype()
{
	# should return with errorlevel 0, and REF=[D|I] (direct, indirect), and TYPE=[v|a|A] (var, array, Array)
	declare_type "$1" && REF=I \
		|| local _var="$1" && declare_type "_var" && REF=D \
		|| return 1 # NFI
	return 0
}

array.push()
{
	scope
	echo "$@"
	getarg array_name && shift

	local _a	# array
	local _A # associative array
	local _i # indirect reference
	local _l # listed, eg: "one" "two" "three"
	local _e # eval format (declare -p without the crap)
	local _d	# full declare statement, including "declare -..."

	local _verbose _quiet	# we don't use these, just as an example for when we copy the argument processing logic
	# We can move all this into a crafy alias one day.
	while [ "${1:0:1}" == "-" ]; do
		case ${1:1:1} in
			q )
				_quiet=1
				;;
			v )
				_verbose=1
				;;
			[a-zA-Z] )
				echo setting $FUNCNAME option ${1:1:1}
				local _${1:1:1}=1
				;;
		esac
		shift
	done
	# argtype "$1" || throw exception "Unknown argument type '$1'"

	(( _A && _e )) &&
	{
		# An associate arrive, declare "eval" style, e.g. "array.push '( [a]=1 ... )'
		# Since it's already compacted, we could just store it as a string... 
		# Lets re-evaluate and re-declare it, to make sure it's valid and we know the format.
		local -A A="$1"
		local len=${#A[@]}
		local first_key="${!A[@]:0:1}"
		# we should check these as:  local -A array=idiot    will produce a valid, associative array.
		local packed="$( declare -p A )"
		echo packed: "$packed"
		eval "$array_name+=\"\$packed\""
	}
	(( _a && _l )) &&
	{
		# This class isn't for storing normal arrays, but hell, lets give it a go. crazy.
		# The luser wants to turn a bunch of function arguments into an array, then store them together 
		# ... thus making a 2D array of sorts.

		local -a array=("$@")
		local len=${#a[@]}
		local first_key="${!a[@]:0:1}"
		local packed="$( declare -p array )"
		echo packed: "$packed"
		eval "$array_name+=(\"\$packed\")"
	}
}

array.copy()
{
	local src; getarg src && shift
	local dst; getarg dst && shift
	
	e="$( declare -p $src )"
	e=${e#*=}
	e=${e#\'}
	e=${e%\'}

	# How to copy an associate array without using eval - locally scoped
	# declare -A G=$e

	# How to copy an associative array (local scope) - should have the surrounding '(xxx)' hard quotes still attached though
	# eval "declare -A A=${e}"
	
	# How to copy a global assoc array - but it has to be declared -A outside the scope of this function
	# 
	declare -Ag $dst
	eval "$dst=$e"	# echo "eval \"$dst=$e\""
}

array.test.get_array_by_ref() 
{
	get_array_by_ref
  	declare -p E
}

array.in_array()
{
	local needle
	local value
	local E

	getarg needle && shift													 # echo needle: $needle
	get_array_by_ref
	for value in "${E[@]}"; do
		echo "$value == $needle"
		[[ $value == $needle ]] && return 0
	done
	return 1
}

# array_search needle hackstack
# returns 0/1 and sets KEY
array.array_search()
{
	local needle
	local E

	getarg needle && shift
	get_array_by_ref
	for KEY in "${!E[@]}"; do
		[[ ${E[$KEY]} == $needle ]] && return 0
	done
	KEY=
	return 1
}

array.example.copying() {
	unset A; declare -A A=( [phil]='phillip' [jamie]='james' )
	unset B; declare -A B; array.copy A B
	unset C; declare -A C=$( array.export A )
	eval $( array.copy.eval A D )

	declare -p A B C D
}
