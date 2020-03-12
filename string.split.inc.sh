function string.split
{
	lo
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
