# Returns a string in which all non-alphanumeric characters except -_.~ have
# been replaced with a percent (%) sign followed by two hex digits.  
#
# Example
# -------
#     easier:    echo http://url/q?=$( rawurlencode "$args" )
#     faster:    rawurlencode "$args"; echo http://url/q?${REPLY}

rawurlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
           [-_.~a-zA-Z0-9] ) o="${c}" ;;
           * )               printf -v o '%%%02x' "'$c"
        esac
        encoded+="${o}"
    done
    echo "${encoded}"    # You can either set a return variable (FASTER) 
    REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
}

# Returns a string in which the sequences with percent (%) signs followed by
# two hex digits have been replaced with literal characters.
# 
# Example
# -------

rawurldecode() {
    # This is perhaps a risky gambit, but since all escape characters must be
    # encoded, we can replace %NN with \xNN and pass the lot to printf -b, which
    # will decode hex for us

    printf -v REPLY '%b' "${1//%/\\x}" # You can either set a return variable (FASTER)

    echo "${REPLY}"  #+or echo the result (EASIER)... or both... :p
}

# support functions for protecting IFS stack (modified by some suggested functions)
declare -a _IFS_STACK=()
declare -a _GLOBAL_STACK=()

setifs() {
    local newifs=${1-$'\x20\x09\x0a'}
    IFS=$newifs
}

pushifs() {
    _IFS_STACK[${#_IFS_STACK[*]}]=$IFS      # push the current IFS into the stack
    [ $# -gt 0 ] && IFS=${1}                # set IFS from argument (if there is one)
}

popifs() {
    local stacklen=${#_IFS_STACK[*]}
    local _={$stacklen:?POP_EMPTY_IFS_STACK}
    (( stacklen -- ))
    IFS=${_IFS_STACK[$stacklen]}
    # echo popped IFS, $stacklen remain in stack
}

rawurlencode_vladr() { 
    local LANG=C 
    local IFS= 
    while read -n1 -r -d "$(echo -n "\000")" c 
    do 
        case "$c" in 
            [-_.~a-zA-Z0-9]) 
                echo -n "$c" 
                ;;
            *) 
                printf '%%%02x' "'$c"
                ;;
        esac 
    done 
}

test_rawurlencode_1() {
    echo input:
    echo "Jogging «à l'Hèze»."
    echo
    echo php urlencode result:
    echo "Jogging%20%C2%AB%C3%A0%20l%27H%C3%A8ze%C2%BB."
    echo
    echo rawurlencode_vladr:
    echo -n "Jogging «à l'Hèze»." | rawurlencode_vladr
    echo 
    echo 
    echo rawurlencode:
    rawurlencode "Jogging «à l'Hèze»."

}

test_rawurlencode_1
