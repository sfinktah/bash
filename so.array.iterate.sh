#!/usr/bin/env bash
    shopt -s expand_aliases
    alias array.getbyref='e="$( declare -p ${1} )"; eval "declare -A E=${e#*=}"'
    alias array.foreach='array.keys ${1}; for key in "${KEYS[@]}"'

    function array.print {
	     array.getbyref
        array.foreach
        do
            echo "$key: ${E[$key]}"
        done
    }
 
    function array.keys {
        array.getbyref
        KEYS=(${!E[@]})
    }

    if [[ $0 = ${BASH_SOURCE[0]} ]]; then
       declare -a A=(the pigs blanket)
       array.print A
    fi

