##
# @file chaser.inc.sh
# @brief 256-color terminal LED chaser
# @author Christopher Anderson
# @version 0.00
# @date 2015-04-30
#!/usr/bin/env bash
trap exit_reset INT

function static {
    local _var=$1 _default=$2
    declare -p "$_var" || declare -g "$_var=$_default"
} > /dev/null 2>&1

function exit_reset {
    local reset="\033[39m\033[49m\033[K\033[?25h"
    echo -en "$reset"
    exit
}

function hide_cursor {
    echo -en "\e[?25l"
}

function reset {
    local reset="\033[39m\033[49m\033[K"
    echo -en "$reset"
}

function chaser {
    local ending=${1-1}
    static __cursor__hidden 0
    static __chaser__length 0
    static __chaser__start -1
    static space_len 8
    static space "        "
    local max_len=$(( 16 * space_len + 2 ))

    (( __cursor__hiden ++ )) || hide_cursor

    (( ++ __chaser__length > ending )) && (( __chaser__length = ending  )) 
    ((    __chaser__start =           ++ __chaser__start % 31 ))

    local a reset="\033[39m\033[49m"
    a=( "\033[48;5;124m"  "\033[48;5;160m"  "\033[48;5;196m"
        "\033[48;5;202m"  "\033[48;5;208m"  "\033[48;5;214m"
        "\033[48;5;220m"  "\033[48;5;226m"  "\033[48;5;190m"
        "\033[48;5;154m"  "\033[48;5;118m"  "\033[48;5;82m"
        "\033[48;5;46m"   "\033[48;5;40m"   "\033[48;5;34m"
        "\033[48;5;28m"   "\033[48;5;22m"   "\033[48;5;28m"
        "\033[48;5;34m"   "\033[48;5;40m"   "\033[48;5;82m"
        "\033[48;5;118m"  "\033[48;5;154m"  "\033[48;5;190m"
        "\033[48;5;226m"  "\033[48;5;220m"  "\033[48;5;214m"
        "\033[48;5;208m"  "\033[48;5;202m"  "\033[48;5;196m"
        "\033[48;5;160m"  "\033[48;5;124m"  "\033[48;5;160m"
        "\033[48;5;196m"  "\033[48;5;202m"  "\033[48;5;208m"
        "\033[48;5;214m"  "\033[48;5;220m"  "\033[48;5;226m"
        "\033[48;5;190m"  "\033[48;5;154m"  "\033[48;5;118m"
        "\033[48;5;82m"   "\033[48;5;46m"   "\033[48;5;40m"
        "\033[48;5;34m"   "\033[48;5;28m"   "Padding4Pretty" )

    local chaser="${a[*]:$__chaser__start:$__chaser__length}" 
    echo -en "${chaser// /$space}"
    echo -en "$reset${space}"
    echo -en "\033[${max_len}D"
}

delay=0.05
while ! read -s -t $delay -n 1
do
    chaser 15
done
for i in {15..0}; do
    chaser $i
    sleep $delay
done
exit_reset
# vim: set ts=4 sts=4 sw=4 et: 
