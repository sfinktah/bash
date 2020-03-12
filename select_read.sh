#!/bin/bash
while true; do
	if read -n 1 -t 1; then
		printf "data ready: %s" "$REPLY"
		break
	fi
	sleep 1
done
