#!/usr/bin/env bash

. include argparser 

function io.readln
{
    read -r
}

function io.writeln
{
    echo "$*"
}

function send
{
    filename="$1"
    pidof nc && kill -TERM $( pgrep -f 'nc -l 1234' )
    sleep 1
    io.writeln "$1"
    nc -l 1234 < "$1"
}


function main.wget
{
    # echo will call "time ssh root@\"$(ArgParser::getArg host)\" \"wget -q -O /tmp/mnc.get \\"$1\\" && cat /tmp/mnc.get\" > \"${1##*/}\"" 
    # time 
   local fn=${1##*/}
   fn=${fn%%?*}
    echo ssh root@"$(ArgParser::getArg host)" "wget -q -O /tmp/mnc.get \"$1\" && cat /tmp/mnc.get" \> "${1##*/}"
    ssh root@"$(ArgParser::getArg host)" "wget -q -O /tmp/mnc.get \"$1\" && cat /tmp/mnc.get" > "${1##*/}"
}
function main.wget.yeah
{
    ssh root@"$(ArgParser::getArg host)" "
    echo hello
    rm -f /tmp/mnc.wget
    kill -TERM \$( pgrep -f 'nc -l 1234' )
    wget --progress=dot:mega -O /tmp/mnc.wget \"$1\" && echo OK
    test -f /tmp/mnc.wget || echo FNF
    bash -c '(nc -l 1234 < /tmp/mnc.wget) &'
    echo killing sshd \$PPID
    kill -TERM \$PPID
    echo killed
    # "
    echo bash killed
    sleep 1
    echo "Getting..." >&2
    local out="$(ArgParser::getArg out)"
    [ -z "$out" ] && out="${1##*/}"
    
    time nc $(ArgParser::getArg host) 1234 > "$out"
    # nc -X connect -x chips10.nt4.com:3128 "$( ArgParser::getArg host )" 1234 | xxd | head
}
function main.bgwget
{
    port=$$
    port=1235
    ssh root@"$(ArgParser::getArg host)" "
    echo hello
    echo wgetting
    wget --progress=dot:mega -O /tmp/$$ \"$1\" &
    sleep 5
    echo GO GO GO GO
    nc -l $port < /tmp/$$
    " &
    sleep 10
    reset
    # read -n 1 -p "Ready to go..."
    local out="$(ArgParser::getArg out)"
    [ -z "$out" ] && out="${1##*/}"
    echo will write to "$out"
    
    # time nc $(ArgParser::getArg host) $port > "$out"
    time nc -X connect -x chips10.nt4.com:3128 "$( ArgParser::getArg host )" $port > "$out"
}
function main.bgwget.o
{
    port=$$
    port=1234
    ssh root@"$(ArgParser::getArg host)" "
    echo hello
    echo wgetting
    wget -q -O - \"$1\" | nc -l $port
    " &
    read -p "Ready to go..."
    local out="$(ArgParser::getArg out)"
    [ -z "$out" ] && out="${1##*/}"
    echo will write to "$out"
    
    # time nc $(ArgParser::getArg host) $port > "$out"
    time nc -X connect -x chips10.nt4.com:3128 "$( ArgParser::getArg host )" $port > "$out"
}
function main.get
{
    # cd /Volumes/mini/TV
    while io.readln
    do
        echo "Receiving: '$REPLY'..."
        sleep 2
        if ArgParser::isset nc
        then
            if [ -e "$REPLY" ]
            then
                echo Ignoring existing file "'$REPLY'"
                # timeout 3 nc -X connect -x chips10.nt4.com:3128 "$( ArgParser::getArg host )" 1234 > /dev/null
                nc -X connect -x chips10.nt4.com:3128 "$( ArgParser::getArg host )" 1234 | xxd | head
                echo "Terminated NC on timeout (el $?)"
                continue
                # return 0
            fi
        fi
        echo nc -X connect -x chips10.nt4.com:3128 "$( ArgParser::getArg host )" 1234 
        nc -X connect -x chips10.nt4.com:3128 "$( ArgParser::getArg host )" 1234 > "$REPLY"
    done
}

function main.put
{
    while test -n "$1"
    do
        files+=( $@ )
        shift
    done
    # ls $files | while read -r 
    for REPLY in "${files[@]}"
    do
        [ -r "$REPLY" ] && 
            echo "Sending: '$REPLY'..." >&2 &&
            send "$REPLY"
    done
}



    # Arguments with a default of 'false' do not take paramaters
    ArgParser::addArg "[q]uiet"   false            "Supress output"
    ArgParser::addArg "[v]erbose" false            "Extra output"
    ArgParser::addArg "[p]ut"     false            "Put files (server mode)"
    ArgParser::addArg "[g]et"     false            "Get files (client mode)"
    ArgParser::addArg "[w]get"    false            "wget file (client mode)"
    ArgParser::addArg "[b]g"      false            "wget enabled background"
    ArgParser::addArg "[o]ut"     ""               "save wget as"
    ArgParser::addArg "[h]elp"    false            "This list"
    ArgParser::addArg "host"      "chips3.nt4.com" "Remote Host"
    ArgParser::addArg "[f]ile"    test             "Files to transfer (unused)"
    ArgParser::addArg "nc"        false            "no clobber (see wget)"

    # set -o xtrace
    # declare -p __arglist
    ArgParser::parse "$@"

    ArgParser::isset help && ArgParser::showArgs && exit 1
    ArgParser::isset "quiet" && echo "Quiet!" >&2

    # set -o xtrace
    ArgParser::isset "host" &&   echo host:    "$(ArgParser::getArg host)"
    ArgParser::isset "put"  &&   echo put:     "${__argparser__argv[@]}" >&2  && main.put  "${__argparser__argv[@]}"
    ArgParser::isset "get"  &&   echo get:     "${__argparser__argv[@]}" >&2  && main.get  "${__argparser__argv[@]}"
    ArgParser::isset "wget" &&   echo wget:    "${__argparser__argv[@]}" >&2 && main.wget "${__argparser__argv[@]}"
    ArgParser::isset "wget" && 
        ArgParser::isset "bg" && echo bg-wget: "${__argparser__argv[@]}" >&2 && main.bgwget "${__argparser__argv[@]}"

    echo finished >&2
    # declare -p | grep __argpassed
