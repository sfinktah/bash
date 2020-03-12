#!/usr/bin/env bash
. include misc

debug_vars() {
	# declare "-p"

#	printf '%20s %-40s\n' '$FUNCNAME' "${FUNCNAME[@]}"
#	printf '%20s %-40s\n' '$BASH_LINENO' "${BASH_LINENO[*]}"
#	printf '%20s %-40s\n' '$BASH_SOURCE' "${BASH_SOURCE[*]}"

	for i in "${!BASH_SOURCE[@]:1}"
	do
		__file=$(basename "${BASH_SOURCE[$i]}")
		__line=${BASH_LINENO[$i-1]}
		__func=${FUNCNAME[$i]}
		printf "%20s:%-4s %s\n" $__file $__line $__func
	done

#          trickle.sh:1    function_trap
#       PeopleControl:788  pplreply
#       PeopleControl:3    ppl
#      savecookies.sh:214  source
#/root/work/cyrus/facebook/newaccounts/facebook.inc.sh:91   sfinktah.facebook.skip.loop
#/root/work/cyrus/facebook/newaccounts/facebook.inc.sh:-1   sfinktah.facebook.skip
#plugins/follow.inc.sh:1    follow
#          trickle.sh:92   trickle::3
#          trickle.sh:2    trickle::loop
#                  $_ trickle::loop

	printf '%20s %-40s\n' '$_' "$_"
	printf '%20s %-40s\n' '$BASH_COMMAND' "${BASH_COMMAND[*]}" 
	printf '%20s %-40s\n' '$BASH_EXECUTION_STRING' "$BASH_EXECUTION_STRING"
	printf '%20s %-40s\n' '$BASH_SUBSHELL' "${BASH_SUBSHELL[*]}"
	printf '%20s %-40s\n' '$BASH_ARGC' "${BASH_ARGC[*]}"
	printf '%20s %-40s\n' '$BASH_ARGV' "${BASH_ARGV[*]}"
	echo "Function Stack:"
	local frame=0

	while caller $frame; do
		((frame++));
	done
	echo

}

throw() {
	echo "initial notification: Exception: $*" >&2
	caller
	  local frame=0
	   
	  while caller $frame; do
		  ((frame++));
	  done
					  
	local exception_type="${1:-exception}"
	local exception_message="${2:-an exception has occured}"
	local exception_handler_name="__CATCH_${exception_type}"
	function_exists "${exception_handler_name}" && {
		decho "... found handler '${exception_handler_name}' for exception $exception_type"
		${exception_handler_name} "$@"
	}
		decho "... no handler for exception $exception_type"
		debug_vars these 'are' "test for" "you"
}

make_exception() {
	throw 
}

function_a() {
	echo
	echo "function a"
	local __CATCH_exception="function a's catcher"
	make_exception
}

function_b() {
	echo
	echo "function b"
	make_exception different than oters

}

exception__test() {
	function_a
	function_b "african" lions "rule the world"
}

# exception__test

# __CATCH_exception="main handler"
# exception__test
