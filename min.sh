min () 
{ 
case `uname` in Linux) SED="sed -r" ;; Darwin) SED="sed -E" ;; *) SED="false" ;; esac;
base64_charset=({A..Z} {a..z} {0..9} + / =); _IFS="$IFS" IFS=
base64_charstring="${base64_charset[*]}" IFS="$_IFS"; text_width=64; line_buffer="";
function display_base64_char () { line_buffer+="${base64_charset[$1]}"; (( width ++ ));
if (( width % text_width == 0 )); then echo "$line_buffer"; line_buffer=""; fi; };
function encode_base64 () { declare -a -i c8 c6; c8=($(( 0x${1:0:2} )) $(( 0x${1:2:2} )) $(( 0x${1:4:2} )));
(( c6[0] = c8[0] >> 2 )); (( c6[1] = ((c8[0] &  3) << 4) | (c8[1] >> 4) )); case ${#c8[*]} in 
3) (( c6[2] = ((c8[1] & 15) << 2) | (c8[2] >> 6) )); (( c6[3] = c8[2] & 63 )) ;;
2) (( c6[2] = (c8[1] & 15) << 2 )); (( c6[3] = 64 )) ;; 1) (( c6[2] = c6[3] = 64 )) ;; esac;
for char in ${c6[@]}; do display_base64_char ${char}; done; };
function strchr () { local trimmed="${1#*$2}"; (( POS = ${#1} - ${#trimmed} - 1 )); };
function strrchr () { local trimmed="${1##*$2}"; (( POS = ${#1} - ${#trimmed} - 1 )); };
function decode_base64 () { c6=(); for current_char in ${1:0:1} ${1:1:1} ${1:2:1} ${1:3:1}; do
strchr "${base64_charstring}" "${current_char}"; (( POS == 64 )) && break; c6=(${c6[*]} ${POS}); done;
(( c8[0] = (c6[0] << 2) | (c6[1] >> 4) )); case ${#c6[*]} in 3)
(( c8[1] = ( (c6[1] & 15) << 4) | (c6[2] >> 2) )); (( c8[2] = (  c6[2] &  3) << 6 )); unset c8[2] ;;
4) (( c8[1] = ( (c6[1] & 15) << 4) | (c6[2] >> 2) )); (( c8[2] = ( (c6[2] &  3) << 6) |  c6[3] )) ;; esac;
for char in ${c8[*]}; do printf -v hex '\\x%x' $char; cstring+=$hex; done;
printf "%b" "$cstring"; cstring=; }; function base64 () { if [ "$1" = "-d" ]; then 
content=$(cat - | tr -d "\n" | $SED "s/(.{4})/\1 /g"); for chars in ${content}; do decode_base64 ${chars}; 
done; else content=$(cat - | xxd -ps -u | $SED 's/([0-9A-F]{6})/\1 /g' ); for chars in ${content};
do encode_base64 ${chars}; done; echo "$line_buffer"; fi; }
}
