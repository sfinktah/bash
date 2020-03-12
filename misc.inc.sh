function_exists() {
	declare -f -F $1 > /dev/null
	return $?
}
# 		function_exists on$CODE && on$CODE ${RARRAY[@]} || \

