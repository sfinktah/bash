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
cat > /dev/null <<END
    string_between(left, right, subject, [,start [,end]] [,greedy=False] [,inclusive=False] [,repl=None] [,retn_all_on_fail=False] [,retn_class=False] [,rightmost=False]) -> str


    Return the substring sub delineated by being between the
    strings \`left\` and \`right\`, and such that sub is contained
    within subject[start:end].  Optional default_arguments start and
    end are interpreted as in slice notation.
    
    Return the string between \`left\` and \`right\` or empty string on failure

    @param left str|re|list: left anchor, or '' for start of subject; regex must be compiled
    @param right str|re|list: right anchor, or '' for end of subject; regex must be compiled
    @param subject: string to be searched
    @param start: start index for search
    @param end: start and end are interpreted as in slice notation.
    @param greedy: match biggest span possible
    @param inclusive: include anchors in result
    @param repl [str|callable]: replace span with string (or callable)
    @param retn_all_on_fail: return original string if match not made
    @param retn_class: return result as StringBetweenResult object
    @param rightmost: match rightmost span possible by greedily searching for \`left\`; implies \`greedy\`
    @return matched span | modified string | original string | empty StringBetweenResult object
    
    Note: regular expressions must be compiled

    If left and right are lists, then string_between() takes a value from
    each list and uses them as left and right on subject. If right has
    fewer values than left, then an empty string is used for the rest of
    replacement values. The converse applies. If left is a list and right 
    is a string, then this replacement string is used for every value of left. 
    The converse also applies.

    Examples:
    ---------

    >>> s = 'The *quick* brown [fox] jumps _over_ the **lazy** [dog]'
    >>> string_between('[', ']', s)
    'fox'

    >>> string_between('[', ']', s, inclusive=True)
    '[fox]'

    >>> string_between('[', ']', s, rightmost=True)
    'dog'

    >>> string_between('[', ']', s, inclusive=True, greedy=True)
    '[fox] jumps _over_ the **lazy** [dog]'

END
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
    # regex for manipulating named variables
    # start|end|inclusive|greedy|rightmost|repl|retn_all_on_fail|retn_class|
    # left, right, subject, start=0, end=None, inclusive=False, greedy=False, rightmost=False, repl=None, retn_all_on_fail=False, retn_class=False
    # vim regex for above: s/\(\w\+\)=\([^ ,]\+\)/.../g

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

    #    l = -2
    #    if v.rightmost:
    #        v.greedy = True
    #        if not right:
    #            llen, l = _string_rfind(subject, left, v.start, v.end)
    #
    #    if l == -2:
    #        llen, l = _string_find(subject, left, v.start, v.end)
    #    
    #    result = StringBetweenResult(l, None, subject, v.retn_class)
    #    if not ~l:
    #        if v.repl is not None or v.retn_all_on_fail: return result.ret(subject, l)
    #        return result.ret(None, l)
    #
    #    if right:
    #        if v.greedy:
    #            rlen, r = _string_rfind(subject, right, v.start, v.end)
    #            if v.rightmost and ~r:
    #                llen, l = _string_rfind(subject, left, v.start, r)
    #        else:
    #            rlen, r = _string_find(subject, right, l + llen, v.end)
    #    else:
    #        rlen = 0

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


    #    if not ~r or r < l + llen:
    #        if v.repl is not None or v.retn_all_on_fail: return result.ret(subject, l, r)
    #        return result.ret('', l, r)
    #    if v.inclusive and r:
    #        r += rlen
    #    else:
    #        l += llen
    #    if v.repl is None:
    #        return result.ret(subject[l:r], l, r)
    #    if callable(v.repl):
    #        return result.ret(subject[0:l] + v.repl(subject[l:r]) + subject[r:], l, r)
    #    return result.ret(subject[0:l] + v.repl + subject[r:], l, r)

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

    # if callable $repl
    #        return result.ret(subject[0:l] + v.repl(subject[l:r]) + subject[r:], l, r)

    REPLY="${subject:0:$l}${repl}${subject:$r}"
    OFFSET=$l
    ROFFSET=$r
    return
}


# string_between "c" "t" "thecatinthematwiththehat" start=7 end=9 greedy=1 why=9
string_between "the" "with" "thecatinthematwiththehatwithoutme" greedy=1 inclusive=1
declare -p REPLY OFFSET ROFFSET
test_url_explosion() {
    url='https://packages.microsoft.com/config/ubuntu/20.04/whatever'
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

test_url_explosion
