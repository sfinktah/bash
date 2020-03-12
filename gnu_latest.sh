#!/usr/bin/env bash
##
# @file gnu_latest.sh
# @brief download and compile latest version of any GNU tool
# @author C Anderson
# @version 1.01
# @date 2015-06-01

##
# @brief gnu_latest download and make GNU tool
#
# n.b., best run from working directory such as /usr/src or ~/src
##
. include decho dprintf
# https://www.torproject.org/dist/torbrowser/4.5.3/tor-browser-linux64-4.5.3_en-US.tar.xz
download_and_make_install ()
{
   local latesturl=$1 && shift
   local app=
   local latestfile=

	if test -z "$app"; then
		app=${latesturl##*/}
		app=${app%%.*}
	fi
	if test -z "$latestfile"; then
		latestfile=${latesturl##*/}
	fi
	dprintf "Latest URL: %s\n" "$latesturl"
   (
   rm -rf "$app.$$"
   mkdir $app.$$ || exit 1
   cd $app.$$ || exit 1
   curl -L "$latesturl" -o "$latestfile"
	tar -xvf "$latestfile"
	# Find the directory that has been created
	for fn in *; do
		if test -d "$fn"; then
			cd "$fn" 
			./configure "$@" 
			make install
		fi
	done
   )
}
gnu_latest_make_install ()
{
   local version
   local app=$1 && shift
   [[ $1 =~ \. ]] && version="-$1." && shift
   local archiver=$1 && shift
   local baseurl="http://ftp.gnu.org/gnu/$app";
	dprintf "baseurl: %s\n" "$baseurl"
   local dirurl="$baseurl/?C=M;O=D";
	dprintf "dirurl: %s\n" "$dirurl"
	# <tr><td valign="top"><img src="/icons/unknown.gif" alt="[   ]"></td>
	# <td><a href="dico-latest.tar.xz.sig">dico-latest.tar.xz.sig</a></td>
	# <td align="right">2012-03-04 09:19  </td><td align="right">189 </td>
	# <td>&nbsp;</td></tr>
   local result=$( 
		curl "$dirurl"                \
		| egrep -o '<a href[^<]+'     \
		| egrep -o '>.*\.tar\.[^.]+$' \
		| head -n1                    \
		;
	)
	dprintf "result: " "$result"
	local latestfile=${result:1}
	archiver=${latestfile##*.} # We don't really care about since tar can
	                           # automatically de-archive
		
   local latesturl="${baseurl}/${latestfile}"
	download_and_make_install "$latesturl"
}

##
# @brief gnu_latest_make_install @gnu_latest_make with install (requires root)
##
# gnu_latest_make_install ()
# {
   # gnu_latest_make "$@" && make install
# }

##
# @brief gnu_latest_list Get list of GNU source packages available
gnu_latest_list ()
{
   :
   # <img src="/icons/folder.gif" alt="[DIR]" /> <a href="bc/">bc/</a>                          02-Aug-2003 07:07    -
   # <img src="/icons/folder.gif" alt="[DIR]" /> <a href="GNUsBulletins/">GNUsBulletins/</a>               24-Mar-2003 18:00
   # <img src="/icons/unknown.gif" alt="[   ]" /> <a href="gnu-keyring.gpg">gnu-keyring.gpg</a>              01-Jun-2015 05:22  1.0M
}

gnu_latest_wget_install ()
{
   cd /usr/src
   gnu_latest_make_install gmp &&
   gnu_latest_make_install nettle 2.7 && # http://comments.gmane.org/gmane.comp.encryption.gpg.gnutls.devel/7532 -- GnuTLS cannot be built against Nettle 3.0. You'll need to use nettle 2.7.
   gnu-latest_make_install gnutls xz &&
   gnu-latest-make_install wget "" --with-libgnutls-prefix=/usr/local &&
   echo done
}
