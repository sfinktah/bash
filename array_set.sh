array_set_array() {
	local _array_name=$1
	shift
	implode $'\xff' "$@"
	eval "$_array_name=\"$IMPLODED\""

}
