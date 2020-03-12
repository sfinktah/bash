which pgrep > /dev/null 2>&1 || function pgrep {
	while [ "${1:0:1}" == "-" ]; do shift; done
	ps -axo pid,command,args | grep -i "$@" | awk '{ print $1 }'
}
