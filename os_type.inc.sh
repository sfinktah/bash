if (( ! ( LINUX || DARWIN || OS_OTHER ) )); then
	case `uname` in 
		Linux )
			LINUX=1
			;;
		Darwin )
			DARWIN=1
			;;
		* )
			OS_OTHER=1
			;;
	esac
fi
