#!/usr/bin/env bash
pdo_sqlsrv=1
sudo=sudo
vendor=$( lsb_release -i -s )
vendor=${vendor,,}
release=$( lsb_release -r -s )
codename=$( lsb_release -c -s )
case "$vendor" in
    debian)
        release=${release%%.*}
        (( release > 10 )) && {
            echo "debian sqlsrv drivers not available for debian > 10" >&2
            exit 1
        }
        ;;
    ubuntu)
        ;;
    *)
        echo "unrecognised vendor '$vendor', we only know how to handle ubuntu and debian"
        exit 1
        ;;
esac


declare -a _IFS_STACK=()
declare -a _GLOBAL_STACK=()

pushifs() {
	_IFS_STACK[${#_IFS_STACK[*]}]=$IFS		# push the current IFS into the stack
	[ $# -gt 0 ] && IFS=${1}						# set IFS from argument (if there is one)
	# [ $# -gt 0 ] # && echo set IFS || echo didnt set ifs
}

popifs() {
	local stacklen=${#_IFS_STACK[*]}
	local _={$stacklen:?POP_EMPTY_IFS_STACK}
	(( stacklen -- ))
	IFS=${_IFS_STACK[$stacklen]}
	# echo popped IFS, $stacklen remain in stack
}

EXPLODED=
IMPLODED=
implode() {
	local c=$#
	(( c < 2 )) && 
	{
		echo implode missing $(( 2 - $# )) parameters >&2
		return 1
	}

	local implode_with="$1"
	shift
	IMPLODED=

	while [ $# -gt 0 ]; do
		IMPLODED+=$1
		shift
		[ $# -gt 0 ] && IMPLODED+=$implode_with
	done
}

# declare -a EXPLODED
explode() {	# included form explode.inc.sh
	local c=$# 
	(( c < 2 )) && 
	{
		echo explode missing parameters 
		return 1
	}
	local delimiter="$1"
	local string="$2"
	local limit=${3-99}

	local delimiter_len=${#delimiter}
	local tmp_delim=$'\x07'
	local delin=${string//$delimiter/$tmp_delim}
	pushifs $'\x07'
	EXPLODED=($delin)
	popifs
	return 0
}

strpos() { 
  x="${1%%$2*}"
  [[ "$x" = "$1" ]] && echo -1 || echo "${#x}"
}

strrpos() { 
  x="${1%$2*}"
  [[ "$x" = "$1" ]] && echo -1 || echo "${#x}"
}

_string_find_common() {
    # def _string_find(haystack, needle, start=0, end=None):
    local func=$1; shift || invalid_args
    local haystack=$1; shift || invalid_args
    local needle=$1; shift || invalid_args
    local -i start=${1:-0}
    local -i end=${2:-${#haystack}}

    # declare -p haystack needle start end

    NEEDLE_LEN=${#needle}
    NEEDLE_POS=$( "$func" "${haystack:$start:$end}" "$needle" )
    (( NEEDLE_POS += start ))
    # return len(needle), haystack.find(needle, start, end)
}
_string_find() {
    _string_find_common strpos "$@"
}

_string_rfind() {
    _string_find_common strrpos "$@"
}

string_between() {
    # get kwargs into variables
    local -A default_arguments=(
        [start]=0
        [end]=None
        [repl]=None
        [inclusive]=0
        [greedy]=0
        [rightmost]=0
        [retn_all_on_fail]=0
        [retn_class]=0
    )

    local left=$1; shift || invalid_args
    local right=$1; shift || invalid_args
    local subject=$1; shift || invalid_args
    ROFFSET=

    while :; do
        arg=$1
        shift || break
        explode "=" "$arg"
        local -i len=${#EXPLODED[@]}
        (( len == 2 )) || { echo "invalid len"; break; }
        k=${EXPLODED[0]}
        v=${EXPLODED[1]}
        [[ ${default_arguments[$k]} == '' ]] && { echo "invalid argument key"; break; }
        default_arguments[$k]=$v
    done

    # declare -p default_arguments

    # start end repl inclusive greedy rightmost retn_all_on_fail retn_class

    for KEY in "${!default_arguments[@]}"; do
        VALUE=${default_arguments[$KEY]}
        local "$KEY"="$VALUE"
    done

    # r = len(subject) - v.start
    local -i subject_len=${#subject}
    local -i llen
    local -i rlen
    local -i l=-2
    local -i r; (( r = subject_len - start ))

    [[ $end == "None" ]] && end=$subject_len

    if (( rightmost )); then
        greedy=1
        if [[ right == '' ]]; then
            # llen, l = _string_rfind(subject, left, v.start, v.end)
            _string_rfind "$subject" "$left" "$start" "$end"
            llen=$NEEDLE_LEN
            l=$NEEDLE_POS
        fi
    fi

    if (( l == -2 )); then
        _string_find "$subject" "$left" "$start" "$end"
        llen=$NEEDLE_LEN
        l=$NEEDLE_POS
        # declare -p NEEDLE_LEN NEEDLE_POS
    fi

    # if not ~l
    if (( l == -1 )); then
        if [[ $repl != "None" || $retn_all_on_fail != 0 ]]; then
            REPLY=${subject:$l}
            OFFSET=$l
            return
        fi
        REPLY=
        OFFSET=$l
        return
    fi

    if [[ $right != "" ]]; then
        if (( greedy )); then
            _string_rfind "$subject" "$right" "$start" "$end"
            rlen=$NEEDLE_LEN
            r=$NEEDLE_POS
            if (( rightmost && r > -1 )); then
                _string_rfind "$subject" "$left" "$start" "$r"
                llen=$NEEDLE_LEN
                l=$NEEDLE_POS
            fi
        else
            _string_find "$subject" "$right" "$(( l + llen ))" "$end"
            rlen=$NEEDLE_LEN
            r=$NEEDLE_POS
        fi
    else
        rlen=0
    fi

    if (( r == -1 || r < ( l + llen ) )); then
        if [[ $repl != "None" || retn_all_on_fail != 0 ]]; then
            REPLY=$subject
            OFFSET=$l
            ROFFSET=$r
            return
        fi
        REPLY=
        OFFSET=$l
        ROFFSET=$r
        return
    fi

    if (( inclusive && r )); then
        (( r += rlen ))
    else
        (( l += llen ))
    fi

    if [[ $repl == "None" ]]; then
        REPLY=${subject:$l:$((r-l))}
        OFFSET=$l
        ROFFSET=$r
        return
    fi

    REPLY="${subject:0:$l}${repl}${subject:$r}"
    OFFSET=$l
    ROFFSET=$r
    return
}

get_available_releases() {
    url=$1
	explode '/' "$url"
	declare -p EXPLODED
	implode '/' "${EXPLODED[@]:0:5}"
	IMPLODED+=/
	declare -p IMPLODED
	VERSIONS=( $(
	while read -r line; do
		# line='<a href="14.04/">14.04/</a>                                             25-Feb-2020 18:54                   -'
		string_between '<a href="' '/">' "$line"
		if [[ $REPLY != "" && ${REPLY:0:1} != "." ]]; then
			echo "$REPLY"
		fi
	done < <( curl -s "$IMPLODED" )
	) )
	echo "Versions: ${VERSIONS[@]}"
}

test_package() {
    local url1=$1; shift
    echo "[INFO]    Retrieving '$url1'" >&2
    read a b c d e < <( curl -s "$url1" )
    if [[ "${c[@]:0:5}" != "https" ]]; then
        echo "[ERROR]   Invalid results received from '$url1'" >&2
        echo "[ERROR]   Supported releases for $vendor: $( get_available_releases "$url1" )"
        return 1
    fi
    local url2="${c}/dists/${d}/Contents-amd64.gz"
    echo "[INFO]    Retrieving '$url2'" >&2
    filecount=$( curl -s "$url2" | gzip -d | grep -E "msodbcsql" | wc -l )
    if (( filecount < 5 )); then
        echo "[ERROR]   Invalid or empty package obtained from '$url'" >&2
        return 1
    fi
	VERSIONS=( $(
	while read -r line; do
		# line='<a href="14.04/">14.04/</a>                                             25-Feb-2020 18:54                   -'
        echo "${line##*/}"
	done < <( curl -s "$url2" | gzip -d | grep -E "msodbcsql" )
	) )
    MSODBCSQL_VER=${VERSIONS[0]}
}

url="https://packages.microsoft.com/config/$vendor/$release/prod.list"
test_package "$url"
# exit 0
curl -s https://packages.microsoft.com/keys/microsoft.asc | $sudo apt-key add -
curl -s https://packages.microsoft.com/config/$vendor/$release/prod.list | $sudo tee /etc/apt/sources.list.d/mssql-release.list
$sudo apt-get update
export ACCEPT_EULA=Y
$sudo apt-get install -y ${MSODBCSQL_VER}
# optional: for bcp and sqlcmd
$sudo apt-get install -y mssql-tools
# echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
# source ~/.bashrc
# optional: for unixODBC development headers
# $sudo apt-get install -y unixodbc-dev

phpver=$( ls /etc/php | tail -n1 )

$sudo pecl install sqlsrv
printf "; priority=20\nextension=sqlsrv.so\n" | $sudo tee /etc/php/$phpver/mods-available/sqlsrv.ini
$sudo phpenmod sqlsrv

if (( pdo_sqlsrv )); then
    $sudo pecl install pdo_sqlsrv
    printf "; priority=30\nextension=pdo_sqlsrv.so\n" | $sudo tee /etc/php/$phpver/mods-available/pdo_sqlsrv.ini
    $sudo phpenmod pdo_sqlsrv
fi
