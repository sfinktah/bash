function handle_error {
	status=$?
	last_call=$1

	# 127 is: command not found
	if [[ $status -ne 127 ]]; then
		return
	fi

	echo "you tried to call $last_call"
	return 1
}

# Trap errors.
trap 'handle_error "$_"' ERR

idiot.love
echo hmmm
