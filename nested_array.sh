#!/bin/bash
# "Nested" array.

#  http://www.macs.hw.ac.uk/~hwloidl/docs/abs-guide/arrays.html#BUBBLE
#  Michael Zick provided this example,
#+ with corrections and clarifications by William Park.

# AnArray=( $(ls --inode --ignore-backups --almost-all \
# 	--directory --full-time --color=none --time=status \
# 	--sort=time -l ${PWD} ) )  # Commands and options.

AnArray=( $(ls -sal ) )

# Spaces are significant . . . and don't quote anything in the above.

SubArray=( ${AnArray[@]:11:1}  ${AnArray[@]:6:5} )
#  This array has six elements:
#+     SubArray=( [0]=${AnArray[11]} [1]=${AnArray[6]} [2]=${AnArray[7]}
#      [3]=${AnArray[8]} [4]=${AnArray[9]} [5]=${AnArray[10]} )
#
#  Arrays in Bash are (circularly) linked lists
#+ of type string (char *).
#  So, this isn't actually a nested array,
#+ but it's functionally similar.

echo "Current directory and date of last status change:"
echo "${SubArray[@]}"

exit 0
