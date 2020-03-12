#!/usr/bin/env bash
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

function Menu.Show.test
{
Menu.Show '([backtitle]="Backtitle"
            [title]="Title"
            [question]="Please choose:")'          \
                                                   \
            "Option A"  "Stuff...."                \
            "Option B"  "Stuff...."                \
            "Option C"  "Stuff...."                
}
