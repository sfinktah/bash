#!/bin/sh
function print_array {
    # eval string into a new assocociative array
    eval "declare -A func_assoc_array="${1#*=}
    # proof that array was successfully created
    declare -p func_assoc_array
}

# declare an assocociative array
declare -A assoc_array=(["key1"]="value1" ["key2"]="value2")
# show assocociative array definition
declare -p assoc_array

# pass assocociative array in string form to function
print_array "$(declare -p assoc_array)"
