function function.copy
{
	local __src=$1
	local __dst=$2
	local __lines

	mapfile __lines < <( declare -f $__src )
	__lines[0]="$__dst()"
	eval "${__lines[@]}"
}
