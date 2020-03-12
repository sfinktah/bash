#!/usr/bin/env bash
#!/usr/bin/env bash
. include array.class

array.new mirrors
unset -v mirrors; declare -a mirrors	# Don't want an associative array
shopt -s expand_aliases
alias add='array.push mirrors -a -l'

# Lets cheat, and only list ones we know we're hosting near

add "Australia" "ftp.au.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
add "Australia Aarnet" "mirror.aarnet.edu.au/pub/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
add "Japan2" "ftp2.jp.debian.org/debian/" "alpha amd64 arm armel armhf hppa hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
add "Japan" "ftp.jp.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
add "United States" "ftp.us.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Austria" "ftp.at.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Belarus" "ftp.by.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Belgium" "ftp.be.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Bosnia and Herzegovina" "ftp.ba.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Brazil" "ftp.br.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Bulgaria" "ftp.bg.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Canada" "ftp.ca.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Chile" "ftp.cl.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "China" "ftp.cn.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Croatia" "ftp.hr.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Czech Republic" "ftp.cz.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Denmark" "ftp.dk.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "El Salvador" "ftp.sv.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Estonia" "ftp.ee.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Finland" "ftp.fi.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
add "France2" "ftp2.fr.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
add "France" "ftp.fr.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
add "Germany2" "ftp2.de.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
add "Germany" "ftp.de.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
add "Great Britain" "ftp.uk.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Greece" "ftp.gr.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Hong Kong" "ftp.hk.debian.org/debian/" "amd64 i386"
# add "Hungary" "ftp.hu.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Iceland" "ftp.is.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Ireland" "ftp.ie.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Italy" "ftp.it.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Korea" "ftp.kr.debian.org/debian/" "alpha amd64 arm armel armhf hppa hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Lithuania" "ftp.lt.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Mexico" "ftp.mx.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
add "Netherlands" "ftp.nl.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "New Caledonia" "ftp.nc.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "New Zealand" "ftp.nz.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Norway" "ftp.no.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Poland" "ftp.pl.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Portugal" "ftp.pt.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Romania" "ftp.ro.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Russia" "ftp.ru.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Slovakia" "ftp.sk.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Slovenia" "ftp.si.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Spain" "ftp.es.debian.org/debian/" "amd64 armel i386 ia64 kfreebsd-amd64 kfreebsd-i386 powerpc"
# add "Sweden" "ftp.se.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Switzerland" "ftp.ch.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Taiwan" "ftp.tw.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Thailand" "ftp.th.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Turkey" "ftp.tr.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"
# add "Ukraine" "ftp.ua.debian.org/debian/" "amd64 armel armhf hurd-i386 i386 ia64 kfreebsd-amd64 kfreebsd-i386 mips mipsel powerpc s390 s390x sparc"

# declare -p mirrors
# echo "${!mirrors[@]}"

noproxy="--no-proxy"
# set -o xtrace
echo "Speed tests are for a 100K file, and a 6MB file. DNS is cached before each test."
echo
# mirrors.foreach
for key in "${!mirrors[@]}"
do
	eval "${mirrors[$key]}"
	printf "%-32s" "${array[0]}: "	# Country :
	hops=$( mtr -r -c 1 ${array[1]%%/*} | wc -l )
	printf "%4s" $hops
	base_url="http://${array[1]}"

	# First wget is to resolve the name
#	echo -n 'dns... '
#	wget -O /dev/null $noproxy --dns-timeout 10 --connect-timeout 3 --read-timeout 3 -q "$base_url/favicon.ico"
#		   # t1=$( grep real /tmp/1 | sed 's/.*m//' | sed 's/s.*//' )
	echo -n '... '
		# "${base_url}dists/stable/main/binary-amd64/Packages.bz2"
	count=0
	for file in "${base_url}../favicon.ico" "${base_url}..." "${base_url}/dists/stable/Release"
	do
		t=$( /usr/bin/time -p wget --tries 1 \
			--dns-timeout 3 \
			--connect-timeout 3 \
			--read-timeout  3 \
			$noproxy \
			-O /dev/null "$file" 2>&1
		)
		el=$?
		# echo "$t"
		t2=
		t3=
		regex='[KM]=([0-9]+.[0-9]+)s'
		if [[ $t =~ $regex ]]; then
			t2="${BASH_REMATCH[1]}"
			# echo Rematch: $t2
		fi
		
		regex='([0-9.]+) KB.s)'
		if [[ $t =~ $regex ]]; then
			t3="${BASH_REMATCH[1]}"
			# echo Rematch: $t3
		fi
		# 2012-06-28 20:42:41 (286 KB/s) - `/dev/null' saved [110865/110865]
		# 49.4 KB/s)
		t1=( $t )
		(( count )) && printf "%6s %6s" "$t2" "$t3"
		(( count++ ))
	done
	echo
done

rm /tmp/$$
# -O /dev/null -q "$base_url/stable/Release" 2>&1
