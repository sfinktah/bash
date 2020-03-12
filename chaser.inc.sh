tr -s '' '\n' | bash <<"EOD" ## Paste this script into a BASH 4 shell
##
# @file chaser.inc.sh
# @brief 256-color terminal LED chaser
# @author Christopher Anderson
# @version 0.00
# @date 2015-04-30
#!/usr/bin/env bash
trap reset INT

function static {
    local _var=$1 _default=$2
    declare -p "$_var" || declare -g "$_var=$_default"
} > /dev/null 2>&1

function reset {
    local reset="\033[39m\033[49m\033[K"
    echo -e "$reset"
    exit
}

function chaser {
    static __chaser__length 0
    static __chaser__start -1

    (( ++ __chaser__length & 16 )) && (( __chaser__length --  )) 
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

    echo -en " ${a[*]:$__chaser__start:$__chaser__length}" 
    echo -en "$reset "
    echo -en "\033[$((__chaser__length+2))D"
}

for i in {0..999}; do
    chaser 
    sleep 0.04
done
# vim: set ts=4 sts=4 sw=4 et: 
EOD
