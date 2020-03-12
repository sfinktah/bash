#!/bin/bash
# Written by Joseph E. Tole 09/29/09
#Updated by G. Geurts 09/30/09

# This creates and then changes to a new temporary directory. mktemp should always be used to avoid accidently using an active file/dir.
export LANG=C
bash_source="$(/bin/mktemp -d)"
cd "${bash_source}"

# Install the bash source.
apt-get source bash

# Dependencies
# The -y flag causes apt-get to assume you said yes and not prompt for y/n to install
apt-get build-dep --force-yes -y bash
apt-get install --force-yes -y dpkg-dev fakeroot
cd bash-*

# This line changes the rules file which has the configure script options predefined in it. This causes the compile to now include network support.
/bin/sed -e 's/--disable-net-redirections/--enable-net-redirections/' -i debian/rules

# This creates new .deb packages for bash which is several but we only need to install one since the others are copies of what is already installed.
/usr/bin/dpkg-buildpackage -rfakeroot -us -uc

# Install the .deb. The asterisk is used for architecture independence. In my case it * matches _amd64 but this is different on non 64 bix x86 systems.
/usr/bin/dpkg -i ../bash*.deb

# The line below puts bash on hold within the package manager so that it is not automatically upgraded. If it is then you will lose this functionality.
echo 'bash hold' | /usr/bin/dpkg --set-selections
