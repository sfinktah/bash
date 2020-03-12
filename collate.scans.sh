#!/usr/bin/env bash
. include arrays array classes upvars exceptions
srcdir="/Users/cyrus/Documents/ANDERSON_IMAGES_RAID_SORTED"
srcdir="/Users/cyrus/Documents/MISC_R2" # S_OF_INTEREST/misc" # { declare -F sc ||
array=($(ls "$srcdir"))

echo "${array[@]}"

#   array_shift pigname array
#   array_push array "sausage"

#   echo the pigs name was $pigname
#   echo and he "${array[@]}"


   # the pigs name was pinky
   # and he went to porky town and bought a pig blanket

newcount=1
newfn="ANDERSON_IMAGES_RAID_SORTED_"
ext=".tif"
array_count array
count=$?
echo $count elements in array
(( half = count / 2 ))
while (( half -- ))
do
	array_shift fn array && 
	{
		printf -v nfn "%s/%s%03d%s" "$srcdir" "$newfn" $(( newcount ++ )) "$ext"
		mv "$srcdir/$fn" "$nfn"
	}
	array_pop fn array && 
	{
		printf -v nfn "%s/%s%03d%s" "$srcdir" "$newfn" $(( newcount ++ )) "$ext"
		mv "$srcdir/$fn" "$nfn"
	}
done

exit
declare -p array

   array_push newarray "start"
   array_push newarray "one"
   array_push newarray '"two"'
   array_push newarray 'three "4" five' 6 seven
   array_push newarray "three" 4 "five"
   declare -p newarray

   array_shift word newarray && declare -p word
   array_shift word newarray && declare -p word
   array_shift word newarray && declare -p word
   array_shift word newarray && declare -p word
   array_shift word newarray && declare -p word
   array_shift word newarray && declare -p word
   array_shift word newarray && declare -p word
   array_shift word newarray && declare -p word
   array_shift word newarray && declare -p word
   array_shift word newarray && declare -p word
}
