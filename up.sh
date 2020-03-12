#!/usr/bin/env bash
t(){ type "$1"&>/dev/null;}

alias cd=cdtrack

function cdtrack {
    local el
    if command cd "$@"; then
       # echo "$( realpath "$PWD" )" >> ~/.cdhistory
       echo "$PWD" >> ~/.cdhistory
    else
       return 1
    fi
}
function trycd {
   TARGET="${1:-$PWD}"
   while IFS=/ read -a line; do 
      for subpath in "${line[@]}"; do
         test -d "${subpath:-/}" || break
         \cd "${subpath:-/}" || break
      done
   done < <( echo "$TARGET" )
}

function cdfind {
    local dirname=$1; shift;
    \cd "$( find . -name "$dirname" -type d | pickone )"
}

function ansi_alt_screen_on {
   echo -en '\e[?1049h'
}
function ansi_alt_screen_off {
   echo -en '\e[?1049l'
}

function up {
   cdup "$@"
}
function cdup {
   local pattern=$1; shift
   local choices=()
   local dirhist=()
   local -i len=0
   local -i found=0
   
   if test -n "$pattern"; then
      mapfile -t dirhist_t < <( egrep "$pattern" ~/.cdhistory | uniq )
      len=${#dirhist_t[@]}
      if [[ ${#dirhist[@]} == 1 ]]; then
         cd "${dirhist[$result]}"
         return;
      fi;
      # (( len > 20 )) && break
      for (( i=len-1; i>=0; i-- )) {
         found=0
         for existing in "${dirhist[@]}"; do
            if [[ $existing == ${dirhist_t[$i]} ]]; then
               echo found "$existing"
               found=1
            fi
         done
         (( !found )) && dirhist+=( "${dirhist_t[$i]}" )
      }
      # dirhist=($(egrep "$pattern" ~/.cdhistory | uniq | tail -n20))
   else
      local -i n=20
      local -i s=0
      for (( n=20; n<200 && s<20 ; n+=10 )) {
         dirhist=()
         s=0
         while IFS= read dir; do 
            dirhist+=("$dir")
            (( s++ ))
         done < <( tail -n$n ~/.cdhistory | awk '!a[$0]++' | tac | tail -n20)
      }
   fi

   for key in "${!dirhist[@]}"; do 
      printf -v value "%q" "${dirhist[$key]}"
      choices+=("$key" "$value")
      # choices+=("$key" "${dirhist[$key]}")
   done

   # whiptail already (breaks) alternate screen 
   # ansi_alt_screen_on
   result=$( Menu.Show '( [backtitle]="Backtitle"
                          [title]="Title"
                          [question]="Please choose:" )'      \
                          "${choices[@]}"  3>&2 2>&1 1>&3-    )
   # ansi_alt_screen_off
   test -n "$result" && cd "${dirhist[$result]}"
}


function ansi_alt_screen_test {
   # echo -e '\e[2J\ec'
   echo regular
   ansi_alt_screen_on
   echo -e '\e[2J'
   echo alt
   ansi_alt_screen_off
   echo returned
}

function pickone {
   local aChoices=()
   local aList=()
   local -i iLen=0
   local -i iFound=0
   local key
   local value
   
   mapfile -t aList
   if [[ ${#aList[@]} == 1 ]]; then
      echo "${aList}"
      return
   fi
   for key in "${!aList[@]}"; do 
      printf -v value "%q" "${aList[$key]}"
      aChoices+=("$key" "$value")
   done

   result=$( Menu.Show '( [backtitle]="Backtitle"
                          [title]="Title"
                          [question]="Please choose:" )'      \
                          "${aChoices[@]}"  3>&2 2>&1 1>&3-   )
   test -n "$result" && echo "${aList[$result]}"
}

__t ()
{
	type "$1" &> /dev/null
}
Menu.Show () 
{ 
    local DIA DIA_ESC;
    while :; do
        __t whiptail && DIA=whiptail && break;
        __t dialog && DIA="dialog --keep-tite" && DIA_ESC=-- && break;
        exec date +s"No dialog program found";
    done;
    declare -A o="$1";
    shift;
    $DIA --backtitle "${o[backtitle]}" --title "${o[title]}" --menu "${o[text]}" 0 0 0 $DIA_ESC "$@"
}

[[ $1 == load ]] || cdup
# vim: set ts=3 sts=0 sw=0 et:
