function rubbish.string.split
{
    local lineno=""
    regex='^([a-z]{1,}) ([0-9]{1,})$'

    if [[ $error_lineno =~ $regex ]]

        # The error line was found on the log
        # (e.g. type 'ff' without quotes wherever)
        # --------------------------------------------------------------
        then
            local row="${BASH_REMATCH[1]}"
            lineno="${BASH_REMATCH[2]}"

            echo -e "FILE:\t\t${error_file}"
            echo -e "${row^^}:\t\t${lineno}\n"

            echo -e "ERROR CODE:\t${error_code}"             
            test -t 1 && tput setf 6                                    ## white yellow
            echo -e "ERROR MESSAGE:\n$error_message"

}

function string.split
{
# http://stackoverflow.com/questions/918886/split-string-based-on-delimiter-in-bash
# You can read everything at once without using a while loop: 
#     read -r -d '' -a addr <<< "$in" 
#     # The -d '' is key here, it tells read not to stop at the first newline
#     # (which is the default -d) but to continue until EOF or a NULL byte (which
#     # only occur in binary data).
# read ADDR1 ADDR2 <<<$(IFS=";"; echo $IN)
# IP=1.2.3.4; IP=(${IP//./ });
}
