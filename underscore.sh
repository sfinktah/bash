. include array classes upvars exceptions

# http://stackoverflow.com/questions/3953645/ternary-operator-in-bash

#
function return_array {
    local r=(e1 e2 "e3  e4" $'e5\ne6')
    local "$1" && upvars -a${#r[@]} $1 "${r[@]}"
}

function sparseup {
	local evalString=$(declare -p $1)
	evalString=${evalString/declare -* $1=\'/$2=}
	unset -v "$2" && eval ${evalString%\'}
}

# This array class is for dealing with -A (associative arrays) found in bash 4 and later, but required bash 4.2 for declare -g
# declare -ar BASH_VERSINFO='([0]="4" [1]="2" [2]="20" [3]="2" [4]="release" [5]="i386-apple-darwin10.8.0")'

if [[ ${BASH_VERSINFO[0]} < 4 || ${BASH_VERSINFO[1]} < 1 ]]
then
	echo This BASH library "(${BASH_SOURCE[0]})" requires BASH 4.1 or later "(for declare -g)" >&2
fi

# Underscoreness

function optimizeCb {
	local out; getarg out && shift
	local func; getarg func && shift
	local context; getarg context && shift
	local argCount; getarg argCount && shift

	unset $out || echo throw invalid out "'$out'"
	eval "$out() {
		scope
		array.length \$this
	};"
}

# s/\v([_a-zA-Z][^, ]+)[, ]?/\r\tlocal \1; getarg \1 \&\& shift/g
function _.each { 
	local obj; getarg obj && shift 
	local iteratee; getarg iteratee && shift 
	local context; getarg context && shift

	# _.each = _.forEach = function(obj, iteratee, context) {
	#   iteratee = optimizeCb(iteratee, context);
	#   var i, length;
	#   if (isArrayLike(obj)) {
	#     for (i = 0, length = obj.length; i < length; i++) {
	#       iteratee(obj[i], i, obj);
	#     }
	#   } else {
	#     var keys = _.keys(obj);
	#     for (i = 0, length = keys.length; i < length; i++) {
	#       iteratee(obj[keys[i]], keys[i], obj);
	#     }
	#   }
	#   return obj;
	# };

	# var keys = _.keys(obj);
	# for (i = 0, length = keys.length; i < length; i++) {
	#	  iteratee(obj[keys[i]], keys[i], obj);
	# }

	array.keys   "$obj"
	array.values "$obj"
	local length=${#KEYS[@]} # local length=$( array.length "$1" )
	for (( i=0; i<length; i++ )); do
		$iteratee "${VALUES[$i]}" "${KEYS[$i]}" "$1"
	done
}

function _.keys {
   local obj;   getarg obj   && shift
   array.keys "$obj"
   echo "${KEYS[@]}"
}

function _.slice {
	local obj;   getarg obj   && shift 
	local begin; getarg begin && shift 
	local end;   getarg end   && shift

cat > :<<'EOD'
####
`_.slice(obj, [begin[, end]])` 
##### begin
Zero-based index at which to begin extraction. 
As a negative index, begin indicates an offset from the end of the
sequence. `slice(-2)` extracts the last two elements in the
sequence. 
If begin is omitted, slice begins from index 0. 
##### end
Zero-based index at which to end extraction. `slice` extracts up to
but not including end. 
`slice(1,4)` extracts the second element up to the fourth element
(elements indexed 1, 2, and 3). 
As a negative index, end indicates an offset from the end of the
sequence. `slice(2,-1)` extracts the third element through the
second-to-last element in the sequence. 
If end is omitted, `slice` extracts to the end of the sequence
(arr.length). 
####
EOD
	end=${end:--0}
	begin=${begin:-0}

	local keys values

	array.keys   "$obj" # sets KEYS
	array.values "$obj" # sets VALUES
	local length=${#KEYS[@]} # local length=$( array.length "$1" )

	[[ $end = "-0" ]] && end=${length}
	(( begin = ( begin < 0 ) ? (length + begin    ) : begin )) 
	(( end   = ( end   < 0 ) ? (length + end      ) : end   )) 

	declare -ag results
	true && { # method 1
		(( end -= begin ))
		results=("${VALUES[@]:$begin:$end}")
	} || { # method 2
	   local i
		for (( i=begin; i<end; i++ )); do
			results+=("${VALUES[$i]}")
		done
	}
}

function array.get {
	get_array_by_ref
	echo "${E[$2]}"
}

shopt -s expand_aliases
alias get_array_by_ref='e="$( declare -p ${1} )"; eval "declare -A E=${e#*=}"'
alias get_indexed_array_by_ref='e="$( declare -p ${1} )"; eval "declare -a E=${e#*=}"'
alias getarg='arg.get "${1}"'

function arg.get {
	# echo getting "$1" into "$2"
	local "$2" && upvar $2 "$1"
}

# clone source dest
function array.export {
	local src; getarg src && shift
	
	e="$( declare -p $src )"
	e=${e#*=}
	e=${e#\'}
	e=${e%\'}
	echo "$e"
}

function array.import {
	local arraydef; getarg arraydef && shift
	local varname; getarg varname && shift

	declare -Ag $varname="$arraydef"
}

function array.length {
	get_array_by_ref
	echo "${#E[@]}"
}

function array.get {
	get_array_by_ref
	echo "${E[$2]}"
}

function array.set {
	local obj;   getarg obj   && shift 
	local key;   getarg key   && shift 
	local value; getarg value && shift

	# local this; this=$1; shift
	# local __key; __key=$1; shift
	# local __value; __value=$1; shift

	declare -g $obj["$key"]="$value"
}

function array.values {
	get_array_by_ref
	VALUES=( "${E[@]}" )
}

function array.keys {
	(( $# )) || throw exception $FUNCNAME is missing an argument
	get_array_by_ref
	KEYS=( "${!E[@]}" )
}

function array.keys.toString
{
	(( $# )) || throw exception $FUNCNAME is missing an argument
	get_array_by_ref
	for key in "${!E[@]}" 
	do
		echo -n "${key},"
	done
}

function array._varname_iterator {
	VARNAME="__ARRAY__ITERATOR__KEYS__$1"
}
function array.reset {
	scope
	$this._varname_iterator "$1"
	$this.keys "$1"
	local $VARNAME="( ${KEYS[*]} )"		# ++ local 'rhs=( alpha beta )'
	declare -a -g $VARNAME="( ${KEYS[*]} )"		# ++ local 'rhs=( alpha beta )'
}

function array.each {
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


function array.new {
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
	eval "$1.set() {
		scope
		array.set \$this \$1 \"\$2\"
	};"
	eval "$1.find() {
		scope
		array.array_search \$1 \$this
	};"
	alias $1.foreach="array.reset $1; array.each $1; for key in "'"${KEYS[@]}"'
}

function array.from_declare {
	scope
	getarg array_name && shift
	$this.new "$array_name"
	getarg declaration

	# Check if it's a full declare (declare -a blah=  .... )  or just a   ([value]... )
	if [[ $declaration =~ ^declare ]]
	then
		declaration="${declaration#*=}"
	fi

	declare -A -g "$array_name"="$declaration"
}

function array.copy.eval {
	local e="$( declare -p ${1} )"
	echo "declare -A $2=${e#*=}"
}

function declare_type {
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
function test_array {
	# must use subscript when assigning associative array
	local r="$( local -A t="$1" 2>&1 )"; [[ $r == "" ]] && echo associative array
	unset t
	local -a t="$1"; echo a: $?
	unset t
	local t="$1"; echo v: $?

}

function argtype {
	# should return with errorlevel 0, and REF=[D|I] (direct, indirect), and TYPE=[v|a|A] (var, array, Array)
	declare_type "$1" && REF=I \
		|| local _var="$1" && declare_type "_var" && REF=D \
		|| return 1 # NFI
	return 0
}

function array.push {
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

function array.copy {
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

function array.test.get_array_by_ref {
	get_array_by_ref
  	declare -p E
}

function array.in_array {
	local needle
	local value
	local E

	getarg needle && shift													 # echo needle: $needle
	get_array_by_ref
	for value in "${E[@]}"; do
		# echo "$value == $needle"
		[[ $value == $needle ]] && return 0
	done
	return 1
}

# array_search hackstack needle
# returns 0/1 and sets KEY
function array.find {
	array.array_search "$@"
}
function array.array_search {
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

function array.example.copying {
	unset A; declare -A A=( [phil]='phillip' [jamie]='james' )
	unset B; declare -A B; array.copy A B
	unset C; declare -A C=$( array.export A )
	eval $( array.copy.eval A D )

	declare -p A B C D
}

function array.example.set {
	:
}

# $ unset a; declare -A a
# $ a[b]=cat
# $ a[e]=fish
# $ eval 'printf "[%s]=\"%s\" "' "\${!$b[@]}" "\$${b[@]}"
# [b]="e" [cat]="fish"
