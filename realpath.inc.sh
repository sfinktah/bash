# http://stackoverflow.com/a/246128/912236

function realpath.help {
	printf 'realpath -dfpqw filename\n'
	printf '  -d   debug output\n'
	printf '  -f   output filename\n'
	printf '  -h   this cruft\n'
	printf '  -p   output path only (default)\n'
	printf '  -q   quote/escape special chars\n'
	printf '  -w   use "which" to local filename\n'
	return 1
} >&2

function decho {
	echo "$@"
}

function realpath {
	local -i options_quote=0
	local -i options_which=0
	local -i options_path=1
	local -i options_file=0
	local -i options_debug=0
	local -i abort=0

	local SOURCE=${BASH_SOURCE[0]}

	while test -n "$1"; do
		case "$1" in
		-q ) options_quote=1;;
		-w ) options_which=1;;
		-d ) options_debug=1;;
		-f ) options_file=1; options_path=0;;
		-p ) options_path=1; options_file=0;;
		-h ) realpath.help; abort=1; break;;
		-* ) echo "Unknown option '$1'" >&2; realpath.help; abort=1; break;;
		*  ) SOURCE=$1;;
		esac
		shift
	done
	(( options_debug )) && decho "SOURCE='$SOURCE'"
	(( break )) && return 1
	(( options_which)) && {
		SOURCE=$( which "$SOURCE" )
		(( options_debug )) && decho "which source: '$SOURCE'"
	}

	while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
	  DIR=$( \cd -P "$( dirname "$SOURCE" )" && pwd )
	  SOURCE=$(readlink "$SOURCE")
	  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
	done
	DIR=$( \cd -P "$( dirname "$SOURCE" )" && pwd )
	test -n "$DIR" && {
		((options_file))  && DIR+="/$( basename "$SOURCE" )"
		((options_quote)) && printf '%q\n' "$DIR" \
			               || printf '%s\n' "$DIR"
	}
}

false && {
	function shutup_cd
	{
		builtin cd "$@" > /dev/null 2>/dev/null
	}
	# . lib.trap.sh
	. warning.inc.sh

	function realpath
	{
		local path=$1
		(
			# Are we looking at a file, or a path (or a link? if that matters)
			test -e "$path" || error "Invalid file/path: $path" 404
			test -d "$path" && path=$( shutup_cd "$path" && pwd )		 \
								 || path="$( shutup_cd `dirname "$path"` && pwd)/$( basename "$path")"
			IFS=/
			a=( $path )																 # Explode the individual components of the path
			f=0
			for d in "${a[@]}"
			do
				[[ "$d" == "" ]] && d=/											 # Actual / in the path is exploded into empty entry
				[[ ! -e "$d" ]] && { echo "Path subcomponent does not exist: '$d'" >&2; break; }
				echo >&2
				echo -n Analysing subcomponent: "$d ... " >&2
				[[ -L "$d" ]] && {
					echo -n "symlink... " >&2
					l=$( readlink "$d" )
					echo -n "to $l ... " >&2
					shutup_cd "$l"
					# f=0
					continue
				}
				[[ -d "$d" ]] && {
					echo -n "directory... " >&2
					# echo -n dir:
					shutup_cd "$d"													 # Changing directories resolves things like a//b 
					# l=$( readlink "$PWD" ) && shutup_cd "$l"
					# echo $l
					# echo "$PWD"
					# f=0
				} || {
					echo -n "file... " >&2
					# l=$( readlink "$d" ) && shutup_cd "$( dirname "$l" )"
					f=1
					# echo "$PWD/$d"
				}
			done
			(( f )) && echo "$PWD/$d" || echo "$PWD"
		)
	} 2>/dev/null
}
# vim: set ts=3 sts=64 sw=3 noet:
