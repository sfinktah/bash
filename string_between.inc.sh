. include upvars explode

strpos() { 
  haystack=$1
  needle=${2//\*/\\*}
  x="${haystack%%$needle*}"
  [[ "$x" = "$haystack" ]] && { echo -1; return 1; } || echo "${#x}"
}

strrpos() { 
  haystack=$1
  needle=${2//\*/\\*}
  x="${haystack%$needle*}"
  [[ "$x" = "$haystack" ]] && { echo -1; return 1 ;} || echo "${#x}"
}

startswith() { 
  haystack=$1
  needle=${2//\*/\\*}
  x="${haystack#$needle}"
  [[ "$x" = "$haystack" ]] && return 1 || return 0
}

endswith() { 
  haystack=$1
  needle=${2//\*/\\*}
  x="${haystack%$needle}"
  [[ "$x" = "$haystack" ]] && return 1 || return 0
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

invalid_args() {
    cat <<'END'
string_between: string_between [-v var] left right subject [start=0] 
                               [end=None] [repl=None] [inclusive=0] 
                               [greedy=0] [rightmost=0] [retn_all_on_fail=0]
    Return the string between `left` and `right`.

    Return the substring `sub` delineated by being between the
    strings `left` and `right`, and optionally such that sub is 
    contained within subject[start:end]. `start` and `end` are 
    interpreted as python slice notation.

    If -v is not supplied, `sub` is stored in the REPLY variable.

    If -s is specified, the result is returned on the standard
    output instead of in a variable.

    Options:
      -v var    assign the result to shell variable VAR 
      -i file   read input from file or '-' to read from 
                the standard input
      -s        display the result on the standard output
      --        end -option processing

    If no substring is found, and either the replace option `repl` 
    or `retn_all_on_fail` option are specified, `subject` is 
    returned.

    If the substring is found, and `repl` is specified, the result 
    will be `subject` with `sub` replaced by `repl`, otherwise
    the matching substring `sub` is returned.

    Exit Status:
    The return code is always zero.

    Example:
        $ string_between "the" "with" "thecatinthematwiththehatwithoutme" \
              greedy=1 inclusive=1
        $ echo $REPLY
        thecatinthematwiththehatwith
END
    return 1
}

string_between () 
{ 
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

    local -A default_arguments=([start]=0 [end]=None [repl]=None [inclusive]=0 [greedy]=0 [rightmost]=0 [retn_all_on_fail]=0 [retn_class]=0 [upvar]=REPLY [infile]=)
    local option_processing=1;
    while (( option_processing )); do
        case "$1" in 
            -v)
                shift;
                default_arguments[upvar]=$1;
                shift
            ;;
            -s)
                default_arguments[upvar]=/dev/stdout;
                shift
            ;;
            -i)
                shift;
                default_arguments[infile]=$1;
                shift
            ;;
            --)
                option_processing=0;
                shift
            ;;
            *)
                option_processing=0
            ;;
        esac;
    done;
    local left=$1;
    shift || invalid_args;
    local right=$1;
    shift || invalid_args;
    local subject
    if [ -n "${default_arguments[infile]}" ]; then
        if [ "${default_arguments[infile]}" = "-" ]; then
            default_arguments[infile]="/dev/stdin"
        fi
        subject=$(cat "${default_arguments[infile]}"; echo -ne '\r'); subject=${subject%\r}
    else
        subject=$1;
        shift || invalid_args;
    fi
    ROFFSET=;
    while :; do
        arg=$1;
        shift || break;
        explode "=" "$arg";
        local -i len=${#EXPLODED[@]};
        (( len == 2 )) || { 
            echo "trailing or invalid arguments";
            break
        };
        k=${EXPLODED[0]};
        v=${EXPLODED[1]};
        [[ ${default_arguments[$k]} == '' ]] && { 
            echo "invalid argument key";
            break
        };
        default_arguments[$k]=$v;
    done;
    for KEY in "${!default_arguments[@]}";
    do
        VALUE=${default_arguments[$KEY]};
        local "$KEY"="$VALUE";
    done;
    local -i subject_len=${#subject};
    local -i llen;
    local -i rlen;
    local -i l=-2;
    local -i r;
    (( r = subject_len - start ));
    [[ $end == "None" ]] && end=$subject_len;
    if (( rightmost )); then
        greedy=1;
        if [[ right == '' ]]; then
            _string_rfind "$subject" "$left" "$start" "$end";
            llen=$NEEDLE_LEN;
            l=$NEEDLE_POS;
        fi;
    fi;
    if (( l == -2 )); then
        _string_find "$subject" "$left" "$start" "$end";
        llen=$NEEDLE_LEN;
        l=$NEEDLE_POS;
    fi;
    if (( l == -1 )); then
        if [[ $repl != "None" || $retn_all_on_fail != 0 ]]; then
            result "${default_arguments[upvar]}" "${subject:$l}";
            OFFSET=$l;
            return;
        fi;
        result "${default_arguments[upvar]}" "";
        OFFSET=$l;
        return;
    fi;
    if [[ $right != "" ]]; then
        if (( greedy )); then
            _string_rfind "$subject" "$right" "$start" "$end";
            rlen=$NEEDLE_LEN;
            r=$NEEDLE_POS;
            if (( rightmost && r > -1 )); then
                _string_rfind "$subject" "$left" "$start" "$r";
                llen=$NEEDLE_LEN;
                l=$NEEDLE_POS;
            fi;
        else
            _string_find "$subject" "$right" "$(( l + llen ))" "$end";
            rlen=$NEEDLE_LEN;
            r=$NEEDLE_POS;
        fi;
    else
        rlen=0;
    fi;
    if (( r == -1 || r < ( l + llen ) )); then
        if [[ $repl != "None" || retn_all_on_fail != 0 ]]; then
            result "${default_arguments[upvar]}" "$subject";
            OFFSET=$l;
            ROFFSET=$r;
            return;
        fi;
        result "${default_arguments[upvar]}" "";
        OFFSET=$l;
        ROFFSET=$r;
        return;
    fi;
    if (( inclusive && r )); then
        (( r += rlen ));
    else
        (( l += llen ));
    fi;
    if [[ $repl == "None" ]]; then
        result "${default_arguments[upvar]}" "${subject:$l:$((r-l))}";
        OFFSET=$l;
        ROFFSET=$r;
        return;
    fi;
    result "${default_arguments[upvar]}" "${subject:0:$l}${repl}${subject:$r}";
    OFFSET=$l;
    ROFFSET=$r;
    return
}
# vim: set ts=4 sts=0 sw=0 et:

result () {
    local __name=$1
    local __value=$2
    if startswith "$__name" /; then
        echo "$__value"
    else
        local $__name && upvar $__name "$__value"
    fi
}

string_between_pipe() {
    exec 3<&0
    while IFS='$\n' read -u 3 -r line || [[ -n "$line" ]]; do
        string_between -s "$@" "$line"
    done
}


# string_between "c" "t" "thecatinthematwiththehat" start=7 end=9 greedy=1 why=9
# string_between "the" "with" "thecatinthematwiththehatwithoutme" greedy=1 inclusive=1
# declare -p REPLY OFFSET ROFFSET
