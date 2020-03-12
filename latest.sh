function gnu_latest {
	which egrep || exec date +"egrep not found"
	which curl || exec date +"curl not found"

	local baseurl="http://ftp.gnu.org/gnu/$1"
	local dirurl="$baseurl/?C=M;O=D"
	local latestfile=$( curl "$dirurl" | egrep -o '>.*?tar.gz<' | head -n1 | egrep -o '"(.*)"' )
	REPLY="${baseurl}/${latestfile//\"}"
	echo "$REPLY"
}

function gnu_download {
	curl -O "$REPLY"
}

function gnu_extract {
	tar zxvf "$REPLY"
}

function gnu_build {
	cd "${REPLY%%.tar.gz}" &&
	./configure && make
}

program=bash
gnu_latest "$program"
gnu_download
REPLY=${REPLY##*/}
gnu_extract
gnu_build
