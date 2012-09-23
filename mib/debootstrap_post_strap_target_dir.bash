#!/bin/bash -ex

#
# RightScript: Poststrap Debootstrap target directory
#
# Description: Post-configures the debootstrap target directory.
# Author: Chris Fordham <chris.fordham@rightscale.com>

# Copyright (c) 2007-2008 by RightScale Inc., all rights reserved worldwide

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Inputs:
: ${DEBOOTSTRAP_RS_VERSION:=v5}				# RightLink v5
: ${DEBOOTSTRAP_TIMEZONE:=UTC}
: ${DEBOOTSTRAP_LOCALE:=en_US}
: ${DEBOOTSTRAP_CHARMAP:=UTF-8}
: ${DEBOOTSTRAP_MODS_ADD:=xfs}
: ${DEBOOTSTRAP_MODS_INSTALL:=false}
: ${DEBOOTSTRAP_PACKAGES_ADD:=openssh-server sysvinit sysvinit-utils sysv-rc python rsync perl ruby openssl curl wget ca-certificates libopenssl-ruby patch alien udev psmisc lsb-release locales dnsutils locate joe vim nano emacs git-core subversion mercurial}
: ${DEBOOTSTRAP_RIGHTLINK_PKG_URL:=http://mirror.rightscale.com/rightlink/5.6.8/ubuntu/rightscale_5.6.8-ubuntu_10.04-amd64.deb}
: ${DEBOOTSTRAP_TARGET_DIR:=/mnt/debootstrap}
: ${AWS_PRIVATE_KEY_FILE:=/root/aws-creds/key.pem}
: ${AWS_CERT_FILE:=/root/aws-creds/cert.pem}
: ${AWS_ACCOUNT_NUMBER:=}
: ${AWS_SECRET_ACCESS_KEY:=}

#
# Debootstrap local configurations
#
DEBOOTSTRAP_TARGET_DIR=`eval echo $DEBOOTSTRAP_TARGET_DIR`		# evaluate the input (commands such as date can be injected)

#
# Package management
#
# add extra apt repositories (updates and security)
echo "deb-src $DEBOOTSTRAP_MIRROR $DEBOOTSTRAP_SUITE main" >> "$DEBOOTSTRAP_TARGET_DIR"/etc/apt/sources.list
echo >> "$DEBOOTSTRAP_TARGET_DIR"/etc/apt/sources.list  # extra line
echo "deb http://security.debian.org/ $DEBOOTSTRAP_SUITE/updates main" >> "$DEBOOTSTRAP_TARGET_DIR"/etc/apt/sources.list
echo "deb-src http://security.debian.org/ $DEBOOTSTRAP_SUITE/updates main" >> "$DEBOOTSTRAP_TARGET_DIR"/etc/apt/sources.list

# Update package list
echo 'Updating packages...'
chroot "$DEBOOTSTRAP_TARGET_DIR" apt-get -y update
chroot "$DEBOOTSTRAP_TARGET_DIR" apt-get -y upgrade
chroot "$DEBOOTSTRAP_TARGET_DIR" apt-get -y dist-upgrade
chroot "$DEBOOTSTRAP_TARGET_DIR" apt-get -f install -y

# Install tasksel standard task
chroot "$DEBOOTSTRAP_TARGET_DIR" tasksel install standard

# Ensure XFS is installed
echo 'Installing XFS.'
chroot "$DEBOOTSTRAP_TARGET_DIR" apt-get -y install xfs xfsprogs

# Install GNU C Library for Xen, libc6-xen if not 64bit
if [ $(chroot "$DEBOOTSTRAP_TARGET_DIR" uname -m) != 'x86_64' ]; then
	chroot "$DEBOOTSTRAP_TARGET_DIR" apt-get -y install libc6-xen
else
	chroot "$DEBOOTSTRAP_TARGET_DIR" apt-get -y install libc6
fi

# Replace dhcp client with dhcpcd
echo 'Installing dhcpcd.'
chroot "$DEBOOTSTRAP_TARGET_DIR" apt-get -y --purge remove isc-dhcp-client isc-dhcp-common dhcp3-client
chroot "$DEBOOTSTRAP_TARGET_DIR" apt-get -y --force-yes install dhcpcd

# Install additional packages
echo 'Installing additional packages...'
if [[ "$DEBOOTSTRAP_PACKAGES_ADD" ]]; then
	chroot "$DEBOOTSTRAP_TARGET_DIR" apt-get -y install $DEBOOTSTRAP_PACKAGES_ADD
fi

# Install Amazon EC2 AMI tools
#echo 'Installing Amazon EC2 tools.'
#cd "$DEBOOTSTRAP_TARGET_DIR"/tmp && \
#wget -q http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.noarch.rpm && \
#chroot "$DEBOOTSTRAP_TARGET_DIR" alien -i --scripts /tmp/ec2-ami-tools.noarch.rpm && \
#rm -v "$DEBOOTSTRAP_TARGET_DIR"/tmp/ec2-ami-tools.noarch.rpm
#ln -sv /usr/lib/site_ruby/aes "$DEBOOTSTRAP_TARGET_DIR"/usr/local/lib/site_ruby/1.8/aes || true
#ln -sv /usr/lib/site_ruby/ec2 "$DEBOOTSTRAP_TARGET_DIR"/usr/local/lib/site_ruby/1.8/ec2 || true

# remove undesirable packages
if [[ $DEBOOTSTRAP_PACKAGES_REMOVE ]]; then
	chroot "$DEBOOTSTRAP_TARGET_DIR" apt-get remove -y "$DEBOOTSTRAP_PACKAGES_REMOVE" || true
fi

# Upgrade/install packages
chroot "$DEBOOTSTRAP_TARGET_DIR" apt-get -y upgrade


#
# Kernel modules installation
#
if [ $DEBOOTSTRAP_MODS_INSTALL != 'false' ]; then
	echo 'Installing extra kernel modules, please wait...'
	arch=`uname -m`
	for module in $DEBOOTSTRAP_MODS_INSTALL; do
		echo 'Installing '"$module"'.'
		curl -s $module | tar -xvzC "$DEBOOTSTRAP_TARGET_DIR"
	done
	for module_version in $(cd "$DEBOOTSTRAP_TARGET_DIR"/lib/modules; ls); do
		chroot "$DEBOOTSTRAP_TARGET_DIR" depmod -a $module_version
	done
	echo 'Done installing extra kernel modules.'
fi
# Add other kernel modules to boot
echo 'Adding modules to /etc/modules.'
echo "$DEBOOTSTRAP_MODS_ADD" >> "$DEBOOTSTRAP_TARGET_DIR"/etc/modules
echo 'Done.'

# These may not have effect due to the kernel auto-loading modules (depending on the kernel)
# Should be ok with xen 2.6.x kernels
# blacklist pcspkr
echo 'Adding blacklist for pcspkr.'
echo 'blacklist pcspkr' > "$DEBOOTSTRAP_TARGET_DIR"/etc/modprobe.d/pcspkr.conf 
echo 'done.'
# blacklist snd-pcsp
echo 'Adding blacklist for snd-pcsp.'
echo 'blacklist snd-pcsp' > "$DEBOOTSTRAP_TARGET_DIR"/etc/modprobe.d/snd-pcsp.conf
echo 'done.'

#
# Configure hostname
#
echo 'Configuring /etc/hostname.'
cat <<'EOF'>$DEBOOTSTRAP_TARGET_DIR/etc/hostname
localhost
EOF
echo 'Done.'


#
# Configure /etc/hosts
#
echo 'Configuring /etc/hosts.'
cat <<'EOF'>$DEBOOTSTRAP_TARGET_DIR/etc/hosts
127.0.0.1	localhost localhost.localdomain

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF
echo 'Done.'

#
# Configure network interfaces
#
echo 'Configuring /etc/network/interfaces.'
cat <<'EOF' >$DEBOOTSTRAP_TARGET_DIR/etc/network/interfaces
# Used by ifup(8) and ifdown(8). See the interfaces(5) manpage or
# /usr/share/doc/ifupdown/examples for more information.

auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF


# set the timezone
echo 'Setting timezone.'
echo "$DEBOOTSTRAP_TIMEZONE" > "$DEBOOTSTRAP_TARGET_DIR"/etc/timezone
/bin/cp -f "$DEBOOTSTRAP_TARGET_DIR"/usr/share/zoneinfo/"$DEBOOTSTRAP_TIMEZONE" "$DEBOOTSTRAP_TARGET_DIR"/etc/localtime
echo 'Done.'

# Set locale
echo 'Setting locale.'
chroot "$DEBOOTSTRAP_TARGET_DIR" apt-get install -y --force-yes
chroot "$DEBOOTSTRAP_TARGET_DIR" localedef -c --inputfile=$DEBOOTSTRAP_LOCALE --charmap=$DEBOOTSTRAP_CHARMAP $DEBOOTSTRAP_LOCALE.$DEBOOTSTRAP_CHARMAP
echo "LANG=\"$DEBOOTSTRAP_LOCALE.$DEBOOTSTRAP_CHARMAP\"" > "$DEBOOTSTRAP_TARGET_DIR"/etc/default/locale
echo 'Done.'

#
# Install and configure extra services
#
# getsshkey service
wget http://rightscale-services.s3.amazonaws.com/scripts%2Finit%2Fgetsshkey.rc.debian.bash -O "$DEBOOTSTRAP_TARGET_DIR"/etc/init.d/getsshkey
chmod -v +x "$DEBOOTSTRAP_TARGET_DIR"/etc/init.d/getsshkey
chroot "$DEBOOTSTRAP_TARGET_DIR" update-rc.d getsshkey start 03 2 3 4 5 .

# ec2-run-user-data service to run user data scripts
wget http://ec2ubuntu.googlecode.com/svn/trunk/etc/init.d/ec2-run-user-data -O "$DEBOOTSTRAP_TARGET_DIR"/etc/init.d/ec2-run-user-data
chmod -v +x "$DEBOOTSTRAP_TARGET_DIR"/etc/init.d/ec2-run-user-data
chroot "$DEBOOTSTRAP_TARGET_DIR" update-rc.d ec2-run-user-data start 90 2 3 4 5 .

# RightScale Agent
echo 'Installing RightScale.'
if [ "$DEBOOTSTRAP_RS_VERSION" = 'v4' ]; then
	echo 'Installing rubygems.'
    chroot "$DEBOOTSTRAP_TARGET_DIR" apt-get install -y rubygems
    rs_version_v4=4.5.0
    cd "$DEBOOTSTRAP_TARGET_DIR"/tmp
    echo 'Fetching RightScale v4 package.'
    wget -q http://rightscale-services.s3.amazonaws.com/rightscale_"$rs_version_v4"-1_all.deb
    echo 'Installing RightScale v4 package.'
    chroot "$DEBOOTSTRAP_TARGET_DIR" dpkg -i /tmp/rightscale_"$rs_version_v4"-1_all.deb
    rm -v "$DEBOOTSTRAP_TARGET_DIR"/tmp/rightscale_"$rs_version_v4"-1_all.deb
else
    # Install rightlink deps
    chroot "$DEBOOTSTRAP_TARGET_DIR" apt-get -y install libc6 debconf curl git-core

    # Install Rightscale v5 (RightLink)
    [ -e "$DEBOOTSTRAP_TARGET_DIR"/etc/rightscale.d ] || mkdir -v "$DEBOOTSTRAP_TARGET_DIR"/etc/rightscale.d

    # set the cloud
    echo ec2 > "$DEBOOTSTRAP_TARGET_DIR"/etc/rightscale.d/cloud

    [ -e "$DEBOOTSTRAP_TARGET_DIR"/tmp ] || mkdir -v  "$DEBOOTSTRAP_TARGET_DIR"/tmp
    cd "$DEBOOTSTRAP_TARGET_DIR"/tmp
    wget -q "$DEBOOTSTRAP_RIGHTLINK_PKG_URL" || echo 'Failed to download RightLink package!'
    RS_IMAGE_INSTALL=true chroot "$DEBOOTSTRAP_TARGET_DIR" dpkg -i /tmp/${DEBOOTSTRAP_RIGHTLINK_PKG_URL##*/}
    rm -v "$DEBOOTSTRAP_TARGET_DIR"/tmp/${DEBOOTSTRAP_RIGHTLINK_PKG_URL##*/}
fi

# install rightimage service
wget -q -O "$DEBOOTSTRAP_TARGET_DIR/etc/init.d/rightimage" https://raw.github.com/rightscale/rightimage/master/cookbooks/rightimage/files/default/rightimage
chmod +x "$DEBOOTSTRAP_TARGET_DIR/etc/init.d/rightimage"
chroot "$DEBOOTSTRAP_TARGET_DIR" update-rc.d rightimage defaults

# ensure sudo is installed
apt-get -y install sudo

# quick sudo setup for rightscale users (usually not needed)
if ! grep rightscale "$DEBOOTSTRAP_TARGET_DIR/etc/sudoers"; then
	echo "%rightscale    ALL=(ALL)    NOPASSWD: ALL" >> "$DEBOOTSTRAP_TARGET_DIR/etc/sudoers"
fi

#
# Security best practices
#
# disable password auth with SSH
perl -pi.orig -e 's/#PasswordAuthentication yes/PasswordAuthentication no/' "$DEBOOTSTRAP_TARGET_DIR"/etc/ssh/sshd_config

#
# Workarounds
#
# Inside Xen, CMOS clock is irrelevant, so save seconds at boot
/bin/rm -f "$DEBOOTSTRAP_TARGET_DIR"/etc/rc?.d/*hwclock*

# needed workaround for squeeze
if [ "$DEBOOTSTRAP_SUITE" = 'squeeze' ]; then
       # was not in repository prior to release
       #cd "$DEBOOTSTRAP_TARGET_DIR"/tmp
       #wget -q http://ftp.us.debian.org/debian/pool/main/u/util-linux/libblkid1_2.17.2-3_i386.deb
       #chroot "$DEBOOTSTRAP_TARGET_DIR" dpkg -i /tmp/libblkid1_2.17.2-3_i386.deb
       #rm -r "$DEBOOTSTRAP_TARGET_DIR"/tmp/libblkid1_2.17.2-3_i386.deb
       chroot "$DEBOOTSTRAP_TARGET_DIR" apt-get -y install libblkid1
       chroot "$DEBOOTSTRAP_TARGET_DIR" ldd /sbin/mkfs.ext2
fi

# fix 4gb seg fixup errors (http://wiki.debian.org/Xen)
echo 'Applying 4gb seg fixup errors fix.' && \
echo 'hwcap 0 nosegneg' > "$DEBOOTSTRAP_TARGET_DIR"/etc/ld.so.conf.d/libc6-xen.conf && chroot "$DEBOOTSTRAP_TARGET_DIR" /sbin/ldconfig

# due to known logical issue with rightlink 5.6.28 startup on plain instances
mkdir -p "$DEBOOTSTRAP_TARGET_DIR"/var/spool/ec2
touch "$DEBOOTSTRAP_TARGET_DIR"/var/spool/ec2/user-data.txt


#
# Cleanup
#

# clean apt
echo 'Running apt autoremove.'
chroot "$DEBOOTSTRAP_TARGET_DIR" apt-get -y autoremove
echo 'Cleaning apt.'
chroot "$DEBOOTSTRAP_TARGET_DIR" apt-get -y clean
chroot "$DEBOOTSTRAP_TARGET_DIR" aptitude -y clean

echo 'Clearing mtab.'
:> "$DEBOOTSTRAP_TARGET_DIR"/etc/mtab

# remove files not to be bundled
echo 'Removing non-bundle files.'
rm -rfv \
"$DEBOOTSTRAP_TARGET_DIR"/usr/sbin/policy-rc.d \
"$DEBOOTSTRAP_TARGET_DIR"/var/log/{bootstrap,dpkg}.log \
"$DEBOOTSTRAP_TARGET_DIR"/var/cache/apt/*.bin \
"$DEBOOTSTRAP_TARGET_DIR"/root/.bash_history \
"$DEBOOTSTRAP_TARGET_DIR"/tmp/*

echo 'Done.'