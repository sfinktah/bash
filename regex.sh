for arg; do
    if [[ $arg =~ ^--([^=]+)=(.*) ]]; then
        optname=${BASH_REMATCH[1]}
        val=${BASH_REMATCH[2]}
        optname_subst=${optname//_/-}
        case "$optname" in 
            basedir) MY_BASEDIR_VERSION="$val" ;;
            datadir) DATADIR="$val" ;;
            ...
        esac
    else
        do something with non-option argument
    fi
done

