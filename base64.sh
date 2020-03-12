#!/usr/bin/env bash
# base64.sh: Bash implementation of Base64 encoding and decoding.
#
# Copyright (c) 2011 vladz <vladz@devzero.fr>
# Used in ABSG with permission (thanks!).
#
#  Encode or decode original Base64 (and also Base64url)
#+ from STDIN to STDOUT.
#
#    Usage:
#
#    Encode
#    $ ./base64.sh < binary-file > binary-file.base64
#    Decode
#    $ ./base64.sh -d < binary-file.base64 > binary-file
#
# Reference:
#
#    [1]  RFC4648 - "The Base16, Base32, and Base64 Data Encodings"
#         http://tools.ietf.org/html/rfc4648#section-5

BASEDIR[$$]="$( dirname "${BASH_SOURCE[0]}" )"
. ${BASEDIR[$$]}/os_type.inc.sh


if (( LINUX )); then
	SED="sed -r"
elif (( DARWIN )); then 
	SED="sed -E"
else
	SED="sed -r"
fi

# The base64_charset[] array contains entire base64 charset,
# and additionally the character "=" ...
base64_charset=( {A..Z} {a..z} {0..9} + / = )
                # Nice illustration of brace expansion.
_IFS="$IFS" IFS= base64_charstring="${base64_charset[*]}" IFS="$_IFS"

#  Uncomment the ### line below to use base64url encoding instead of
#+ original base64.
### base64_charset=( {A..Z} {a..z} {0..9} - _ = )

#  Output text width when encoding
#+ (64 characters, just like openssl output).
text_width=64
line_buffer=""

function display_base64_char {
#  Convert a 6-bit number (between 0 and 63) into its corresponding values
#+ in Base64, then display the result with the specified text width.
  line_buffer+="${base64_charset[$1]}"
  (( width ++ ))
  # printf "${base64_charset[$1]}"; (( width++ ))
  if (( width % text_width == 0 )); then
	  echo "$line_buffer"
	  line_buffer=""
  fi
}

function encode_base64 {
# Encode three 8-bit hexadecimal codes into four 6-bit numbers.
  #    We need two local int array variables:
  #    c8[]: to store the codes of the 8-bit characters to encode
  #    c6[]: to store the corresponding encoded values on 6-bit
  declare -a -i c8 c6

  #  Convert hexadecimal to decimal.
  # c8=( $(printf "ibase=16; ${1:0:2}\n${1:2:2}\n${1:4:2}\n" | bc) )
  c8=( $(( 0x${1:0:2} )) $(( 0x${1:2:2} )) $(( 0x${1:4:2} )) )

  #  Let's play with bitwise operators
  #+ (3x8-bit into 4x6-bits conversion).
  (( c6[0] = c8[0] >> 2 ))
  (( c6[1] = ((c8[0] &  3) << 4) | (c8[1] >> 4) ))

  # The following operations depend on the c8 element number.
  case ${#c8[*]} in 
    3) (( c6[2] = ((c8[1] & 15) << 2) | (c8[2] >> 6) ))
       (( c6[3] = c8[2] & 63 )) ;;
    2) (( c6[2] = (c8[1] & 15) << 2 ))
       (( c6[3] = 64 )) ;;
    1) (( c6[2] = c6[3] = 64 )) ;;
  esac

  for char in ${c6[@]}; do
    display_base64_char ${char}
  done
}

### 
# @brief locates the first occurrence of c in a string
# @description 
#    The strchr() function locates the first occurrence of c ($2) in the string s ($1).  
# @return
#    The functions strchr() and strrchr() return set the variable $POS to
#    indicate the offset of the located character, or -1 if the character does
#    not appear in the string.
###

strchr() {
	local trimmed="${1#*$2}"
	(( POS = ${#1} - ${#trimmed} - 1 ))
}

strrchr() {
	local trimmed="${1##*$2}"
	(( POS = ${#1} - ${#trimmed} - 1 ))
}
  

# declare -a -i c8 c6															 
function decode_base64 {
  # set -o xtrace
	# Decode four base64 characters into three hexadecimal ASCII characters.
  #  c8[]: to store the codes of the 8-bit characters
  #  c6[]: to store the corresponding Base64 values on 6-bit

  c6=()

  # Find decimal value corresponding to the current base64 character.
  for current_char in ${1:0:1} ${1:1:1} ${1:2:1} ${1:3:1}; do
     # [ "${current_char}" = "=" ] && break

#     position=0
	  strchr "${base64_charstring}" "${current_char}"
	  (( POS == 64 )) && break

#     while [ "${current_char}" != "${base64_charset[${position}]}" ]; do
#        (( position++ ))
#     done

     c6=( ${c6[*]} ${POS} )
  done

  #  Let's play with bitwise operators
  #+ (4x8-bit into 3x6-bits conversion).
  (( c8[0] = (c6[0] << 2) | (c6[1] >> 4) ))

  # The next operations depends on the c6 elements number.
  case ${#c6[*]} in
    3) (( c8[1] = ( (c6[1] & 15) << 4) | (c6[2] >> 2) ))
       (( c8[2] = (  c6[2] &  3) << 6 )); unset c8[2] ;;
    4) (( c8[1] = ( (c6[1] & 15) << 4) | (c6[2] >> 2) ))
       (( c8[2] = ( (c6[2] &  3) << 6) |  c6[3] )) ;;
  esac

#  printf -v hex '%08x' $_packet_length
#  local packet_length=""
#  while (( ${#hex} )); do
#	  packet_length+="\\x${hex:0:2}"
#	  hex="${hex:2}"
#  done

  for char in ${c8[*]}; do
     printf -v hex '\\x%x' $char
	  cstring+=$hex
  done
  printf "%b" "$cstring"
  cstring=
}


base64()
{

# main ()

if [ "$1" = "-d" ]; then   # decode

  # Reformat STDIN in pseudo 4x6-bit groups.
  content=$(cat - | tr -d "\n" | $SED "s/(.{4})/\1 /g")
  echo entering loop >&2

  for chars in ${content}; do decode_base64 ${chars}; done
  printf "%b" "$cstring"

else
  # Make a hexdump of stdin and reformat in 3-byte groups.
  # content=$(cat - | xxd -ps -u | $SED 's/(\w{6})/\1 /g' | tr -d "\n")
  content=$(cat - | xxd -ps -u | $SED 's/([0-9A-F]{6})/\1 /g' )
  # export content
  # echo "$content"

  for chars in ${content}; do 
	  # echo Chars: "${chars}"
	  encode_base64 ${chars}; 
  done

  echo "$line_buffer"
fi
}
# vim: set ts=3 sts=64 sw=3 noet:
