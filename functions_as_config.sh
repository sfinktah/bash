#!/usr/bin/env bash

### This would go in config_pre.inc.sh
config_groups=(
	location
	server
	ssl
	vhost
)

shopt -s expand_aliases

for group in "${config_groups[@]}"; do
	alias "$group"="function config_set.$group"
	# eval "function config_set.$group { config_set '$group' \"\$@\"; }"
done
### end of config_pre.inc.sh

# . config_pre.inc.sh

### this would leave us a nice clear looking config file, eg:

server {
	port	8080;  # trailing semi-colon is ignored but permitted
	admin	'"Local Admin" <admin@localhost>'	# quote within quotes
	name	"$( cat /etc/hostname )"	# use the shell, luke.
}

ssl {
	protocols	"TLSv1 TLSv1.1 TLSv1.2"	# quote anything with spaces
	ciphers		"DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:!DES"
								# '!' needs to be quoted?
}

location {
	root	"/opt/html"
	index	index.{htm,html}	# brace expansion, can't quote
}

vhost {
	name	"www.vhost.com"
	aka		"vhost.com"
	aka		"*.vhost.com"
	root	"/opt/virtual/vhost"
}

# . config_post.inc.sh

### and the rest goes in config_post.inc.sh

function config_set {
	local arg

	printf "config_set "
	printf "%q " "$@"
	printf "\n"

	printf -v arg[0] -- "--%s-%s" "$1" "$2"; shift 2
	printf -v arg[1] "%q " "$@"
	cmd_args+=( "${arg[@]}" )
}


function transform {
	local group=$1; shift
	while (( $# )); do
		if [[ ${1:0:1} = ' ' ]]; then
			printf '    config_set "%s" %s\n' "$group" "$1"
		else
			printf '%s\n' "$1"
		fi
		shift
	done
}


for group in "${config_groups[@]}"; do
	fn="config_set.$group"
	if declare -F "$fn" >/dev/null 2>&1
	then
		contents=()
		while IFS= read -r line; do contents+=( "$line" ); done < <( declare -f "$fn")
		source <( transform "$group" "${contents[@]}" )
		# declare -f "$fn"
		$fn
	fi
done

echo 
echo "./rwasa ${cmd_args[@]}"

###

### RESULT:
### ./rwasa --location-root /opt/html  --location-index index.htm index.html  --server-port 8080 \
###         --server-admin \"Local\ Admin\"\ \<admin@localhost\>  --server-name ''               \
###         --ssl-protocols TLSv1\ TLSv1.1\ TLSv1.2  --ssl-ciphers                               \
###         DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:\!DES  --vhost-name www.vhost.com        \
###         --vhost-aka vhost.com  --vhost-aka \*.vhost.com --vhost-root /opt/virtual/vhost

# vim: set ts=4 sts=0 sw=4 noet:
