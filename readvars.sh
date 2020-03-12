#!/usr/bin/env bash
. include array 

cat > /dev/null <<EOEXAMPLE
IP="109.73.161.186"
FIRST="Hawa"
LAST="Tiey"
EMAIL="hawa31@aol.com"
PASS="ht5142844"
YAHOO_PASS="abcd1237"
DAY="2"
MONTH="2"
YEAR="87"
GENDER="m"
TZ="Asia/Calcutta"
HEIGHT="671"
WIDTH="1280"
UAGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_5_8) AppleWebKit/534.50.2 (KHTML, like Gecko) Version/5.0.6 Safari/533.22.3"
COUNTRY=""
GIFTCARDPIN=""
PICFILENAME=""
HIGHSCHOOL=""
FRIENDS=""
SECANSWER=""
DELAY="249.32432432432432"
ACCURACY="0.92160727000000"
EOEXAMPLE

function readParms {
   local parmFile=$1
   local modFunction=$2
   local VARNAME VALUE A key blah
   local IFS="="
   local -A ParmArray
   while read -r VARNAME VALUE
   do
      # printf "%q=%q\n" "$VARNAME" "$VALUE"
      VALUE=${VALUE#\"}
      VALUE=${VALUE%\"}
      declare ParmArray["$VARNAME"]="$VALUE"
   done < "$parmFile"
   # Now, lets modify what we need
   test -n "$modFunction" && 
      $modFunction ParmArray
   false && 
   for key in "${!ParmArray[@]}"
   do
      false && {
         # This is a little more complex, but it makes nicer strings
         printf -v tmp "%s" "${ParmArray["$key"]}"
         blah=$( declare -p tmp )
         blah="$key=${blah#*tmp=}"
         printf "%s\n" "$blah"
      } || {
         # This makes lots of ugly escapes instead of just quoting
         printf "%s=%q\n" "$key" "${ParmArray["$key"]}"
      }
   done
   e=$(declare -p ParmArray)
   e=${e#*=}
   echo "$e"

}

function modFunction {
   local arrayName=$1
   declare -g $arrayName["ANIMAL"]="COW"
}
# readParms parms.sh modFunction
arg.get.shift()
{
   # echo getting "$1" into "$2"
   local "$2" && upvar $2 "$1" && shift
}

alias localArg='arg.get.shift "${1}"'

declare -A ParmArray
function using {
   local type;          getarg type && shift
   local source;        getarg source && shift
   local verb;          getarg verb && shift
   local destination;   getarg destination && shift

   declare -gA "$destination"
   echo "type: $type"
   case "$type" in
   file )
      echo "destination: $destination"
      p=$(readParms $source)
      eval declare -gA "$destination"=$p
      declare -p "$destination"
      array.keys "$destination"
      for key in "${KEYS[@]}"
      do
         echo "setting alias on '$key'"
         declare -gn "$key"="$destination["$key"]"
      done
      ;;
   esac
}

function write.Array {
   local fn; getarg fn && shift
   get_array_by_ref
   for k in ${!E[@]}
   do
      printf "%s=%q\n" "$k" "${E[$k]}"
   done
}



function main {
   using file parms.sh as parms
   GIFTCARDPIN="Test"
   write.Array parms
}

