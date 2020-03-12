# debug only printing aliases
function dprintf
{
	(( __DEBUG )) && printf "$@"
}
