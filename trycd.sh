#!/usr/bin/env bash

function trycd {
   TARGET="${1:-$PWD}"
   while IFS=/ read -a line; do 
      for subpath in "${line[@]}"; do
         cd "${subpath:-/}" || break
      done
   done < <( echo "$TARGET" )
}

