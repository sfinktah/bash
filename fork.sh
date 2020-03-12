#!./socketpair /opt/local/bin/bash
. ../bash/upvars.inc.sh

_val=0
output() {
	count=$1
	echo $count
	_val="$count"
}

output_upvar() {
	count=$1
	local "$2" && upvar $2 "$1"
}

output_eval() {
	count=$1
	eval "$2=$1"
}

# local "$1" && upvar $1 "value(s)"
pipevar() {
	read 
	local "$1" && upvar $1 "$REPLY"
}

method() {
	val=0;
	for (( i=0 ; i<2000; i++ )); do
		case $1 in 
			a )
				val=$( output $i )
				;;
			b )
				output $i > /tmp/$$
				pipevar val < /tmp/$$
				# rm /tmp/$$
				;;
			c )
				output $i | pipevar val
				;;
			d )
				pipevar val < <( output $i )
				;;
			e )
				fd=<( output $i )
				pipevar val < $fd
				;;
			f )
				if [ ! -z "$DUP1" ]; then
					output $i >& $DUP1
					pipevar val <& $DUP2
				fi
				;;
			g )
				output $i 
				val="$_val"
				;;
			h ) 
				if [ ! -z "$DUP1" ]; then
					output $i >& $DUP1
					read -u $DUP2 val
				fi
				;;
			i )
				output_upvar $i val
				;;
			j )
				output_eval $i val
				;;
			k )
				__=${val:0:1}
				;;
			l )
				__=${val[0]}
				;;
		esac
	done > /dev/null
	echo -n "$val "
}

declare -a methods
methods=( a b c d e f g h i j k l )
for m in ${methods[@]}; do
	echo -n "method $m: "
	time method $m
done
