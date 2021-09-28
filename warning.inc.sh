# http://stackoverflow.com/questions/64786/error-handling-in-bash/18118450#18118450
debug()
{
    # Output info messages
    # Color the output (unknown) if it's an interactive terminal
    # @param $1...: Messages

    test -t 1 && tput setf 3

    printf '%s\n' "$@" >&2

    test -t 1 && tput sgr0 # Reset terminal
    true
}

info()
{
    # Output info messages
    # Color the output (unknown) if it's an interactive terminal
    # @param $1...: Messages

    test -t 1 && tput setf 2

    printf '%s\n' "$@" >&2

    test -t 1 && tput sgr0 # Reset terminal
    true
}

warning()
{
    # Output warning messages
    # Color the output red if it's an interactive terminal
    # @param $1...: Messages

    test -t 1 && tput setf 4

    printf '%s\n' "$@" >&2

    test -t 1 && tput sgr0 # Reset terminal
    true
}

error()
{
    # Output error messages with optional exit code
    # @param $1...: Messages
    # @param $N: Exit code (optional)

    messages=( "$@" )

    # If the last parameter is a number, it's not part of the messages
    last_parameter="${messages[@]: -1}"
    if [[ "$last_parameter" =~ ^[0-9]*$ ]]
    then
        exit_code=$last_parameter
        unset messages[$((${#messages[@]} - 1))]
    fi

    warning "${messages[@]}"

    exit ${exit_code:-$EX_UNKNOWN}
}
