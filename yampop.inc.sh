### yet another (inefficicent) version of array manipulation

##
# @brief 
#
# @param array_name name of the array (eg: "array")
# @param array_values the values in the array (eg: "${array[@]}")
#
# @return will change /array/ and return popped value in /REPLY/
function yam.pop #( array_name, array_values[@] )
{
	local __aname=$1		# Make a copy of the array name
	shift
	local __a=( "$@" )	# Make a local copy of the array (why?)
	local __l=$#			# Get the length of the array
	local __last=$(( __l - 1 ))	# Get the last index in the array

	# REPLY=${__a[$(( __l -1 ))]}	# Get the last value in the array ( a[len -1] )
	REPLY=${__a[$__last]}	# Get the last value in the array ( a[len -1] )

	
	# We'll have to use an /eval/ to do the unsetting, so best we check the variable exists, and isn't caustic

	declare -p "$__aname" > /dev/null || return	# If it is caustic, or invalid, we simply return the popped value in REPLY, and don't worry about it
	eval unset $__aname[\$__last]	# unset will take a variable as an index, so might as well show off :p
}
