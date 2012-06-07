#! /bin/bash -e

# RightScript: MIB: Centosbootstrap
#
# Description: Bootstraps a base CentOS system.
#
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

# install build requirements
apt-get -y install yum rpm python-m2crypto

: ${CENTOS_ARCH:=`uname -m`}
: ${CENTOS_KERNEL_VERSION:=2.6.32-220.7.1.el6.centos.plus}
: ${CENTOSBOOTSTRAP_CHROOT:=/mnt/mib.master}
: ${RIGHTLINK_VERSION:=5.7.14}
: ${EPEL_RELEASE:=6-7}
#: ${RIGHTLINK_PKG_URL:=}

# silently ensure proc and sysfs are unmounted
chroot "$CENTOSBOOTSTRAP_CHROOT" umount /proc > /dev/null 2>&1 || true
chroot "$CENTOSBOOTSTRAP_CHROOT" umount /sys > /dev/null 2>&1 || true

rm -Rf "$CENTOSBOOTSTRAP_CHROOT/*"  # remove all previous straps
mkdir -p "$CENTOSBOOTSTRAP_CHROOT"
mkdir -p "$CENTOSBOOTSTRAP_CHROOT/dev"
mkdir -p "$CENTOSBOOTSTRAP_CHROOT/proc"
mkdir -p "$CENTOSBOOTSTRAP_CHROOT/etc"
mkdir -p "$CENTOSBOOTSTRAP_CHROOT/sys"
mkdir -p "$CENTOSBOOTSTRAP_CHROOT/var/lib/rpm"
mkdir -p "$CENTOSBOOTSTRAP_CHROOT/etc/yum.repos.d"

touch "$CENTOSBOOTSTRAP_CHROOT/etc/fstab"
touch "$CENTOSBOOTSTRAP_CHROOT/etc/mtab"

## Needs before and after for logical reasons
# resolv.conf
host_ns="$(grep nameserver /etc/resolv.conf | head -n1)"
echo "$host_ns" > "$CENTOSBOOTSTRAP_CHROOT/etc/resolv.conf"
echo "nameserver    8.8.8.8" >> "$CENTOSBOOTSTRAP_CHROOT/etc/resolv.conf"
echo "nameserver    4.2.2.1" >> "$CENTOSBOOTSTRAP_CHROOT/etc/resolv.conf"
# fstab (initial/blank)
echo "# fstab - static information about the filesystems" > "$CENTOSBOOTSTRAP_CHROOT/etc/fstab"

# init rpm
rpm --root "$CENTOSBOOTSTRAP_CHROOT" --initdb

arch="$CENTOS_ARCH"
if [ "$CENTOS_ARCH" = 'i686' ]; then
    arch=i386
fi

# install base centos repos pkg
cd /tmp
repos_rpm_url="http://mirror.centos.org/centos/6/os/$arch/Packages/centos-release-6-2.el6.centos.7.$CENTOS_ARCH.rpm"
wget "$repos_rpm_url"
rpm -ivh --replacepkgs --force-debian --nodeps --root "$CENTOSBOOTSTRAP_CHROOT" centos-release*rpm
# (standard, manual)
# cd /tmp; wget http://mirror.rightscale.com/centos/6/os/i386/archive/latest/Packages/centos-release-6-2.el6.centos.7.i686.rpm && rpm -ivH --force ./centos-release-6-2.el6.centos.7.i686.rpm
mkdir -p /etc/pki
cp -Rv "$CENTOSBOOTSTRAP_CHROOT"/etc/pki/rpm-gpg /etc/pki/

# install yum + clean
yum -y --installroot "$CENTOSBOOTSTRAP_CHROOT" install yum
chroot "$CENTOSBOOTSTRAP_CHROOT" yum clean all

## Needs before and after for logical reasons
# resolv.conf
host_ns="$(grep nameserver /etc/resolv.conf | head -n1)"
echo "$host_ns" > "$CENTOSBOOTSTRAP_CHROOT/etc/resolv.conf"
echo "nameserver    8.8.8.8" >> "$CENTOSBOOTSTRAP_CHROOT/etc/resolv.conf"
echo "nameserver    4.2.2.1" >> "$CENTOSBOOTSTRAP_CHROOT/etc/resolv.conf"
# fstab (initial/blank)
echo "# fstab - static information about the filesystems" > "$CENTOSBOOTSTRAP_CHROOT/etc/fstab"

# prepare target
chroot "$CENTOSBOOTSTRAP_CHROOT" yum -y install bash		# ensure bash/sh is installed from here

# base
cat <<'EOF'> "$CENTOSBOOTSTRAP_CHROOT/etc/yum.repos.d/CentOS-Base.repo"
# CentOS-Base.repo
#
# The mirror system uses the connecting IP address of the client and the
# update status of each mirror to pick mirrors that are updated to and
# geographically close to the client.  You should use this for CentOS updates
# unless you are manually picking other mirrors.
#
# If the mirrorlist= does not work for you, as a fall back you can try the 
# remarked out baseurl= line instead.
#
#

# note: rs mirrors are not used as these are don't mirror release 6.2
[base]
name=CentOS-$releasever - Base
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os
#baseurl=http://mirror.centos.org/centos/$releasever/os/$basearch/
#baseurl = http://cf-mirror.rightscale.com/centos/6/os/i386/archive/latest
# http://ec2-ap-southeast-mirror1.rightscale.com/centos/6/os/i386/archive/latest
# http://ec2-ap-southeast-mirror2.rightscale.com/centos/6/os/i386/archive/latest
# http://ec2-us-west-mirror.rightscale.com/centos/6/os/i386/archive/latest
failovermethod=priority
priority=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
exclude=kernel kernel-devel
enabled=1
EOF

cat <<'EOF'> "$CENTOSBOOTSTRAP_CHROOT/etc/yum.repos.d/CentOS-Updates.repo"
#released updates 
[updates]
name=CentOS-$releasever - Updates
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates
#baseurl=http://mirror.centos.org/centos/$releasever/updates/$basearch/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
EOF

cat <<'EOF'> "$CENTOSBOOTSTRAP_CHROOT/etc/yum.repos.d/CentOS-Extras.repo"
#additional packages that may be useful
[extras]
name=CentOS-$releasever - Extras
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras
#baseurl=http://mirror.centos.org/centos/$releasever/extras/$basearch/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
EOF

cat <<'EOF'> "$CENTOSBOOTSTRAP_CHROOT/etc/yum.repos.d/CentOS-Plus.repo"
#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-$releasever - Plus
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=centosplus
#baseurl=http://mirror.centos.org/centos/$releasever/centosplus/$basearch/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
includepkgs=kernel* jfsutils reiserfs-utils
EOF

cat <<'EOF'> "$CENTOSBOOTSTRAP_CHROOT/etc/yum.repos.d/CentOS-Contrib.repo"
#contrib - packages by Centos Users
[contrib]
name=CentOS-$releasever - Contrib
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=contrib
#baseurl=http://mirror.centos.org/centos/$releasever/contrib/$basearch/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
EOF

# epel repos
# mirror list: http://mirrors.fedoraproject.org/publiclist/EPEL/
epel_mirror="http://mirror.utexas.edu/epel"
chroot "$CENTOSBOOTSTRAP_CHROOT" rpm -ivH --replacepkgs "$epel_mirror/6/$AMI_ARCH/epel-release-$EPEL_RELEASE.noarch.rpm"
#chroot "$CENTOSBOOTSTRAP_CHROOT" rpm -iv --replacepkgs http://dl.iuscommunity.org/pub/ius/stable/Redhat/6/i386/epel-release-6-5.noarch.rpm

# ius repos
chroot "$CENTOSBOOTSTRAP_CHROOT" rpm -ivH --replacepkgs "http://dl.iuscommunity.org/pub/ius/stable/Redhat/6/$arch/ius-release-1.0-10.ius.el6.noarch.rpm"       # IUS Community Project (IUS) repository
#rm -v "$CENTOSBOOTSTRAP_CHROOT/etc/yum.repos.d/epel-testing.repo" || true

# keep it updated
chroot "$CENTOSBOOTSTRAP_CHROOT" yum -y update
chroot "$CENTOSBOOTSTRAP_CHROOT" yum -y upgrade
chroot "$CENTOSBOOTSTRAP_CHROOT" yum clean all

# install base system
chroot "$CENTOSBOOTSTRAP_CHROOT" yum -y install yum rpm centos-release coreutils basesystem setup filesystem libstdc++ udev MAKEDEV chkconfig bash glibc glibc-common libgcc tzdata mktemp

# mount image filesystems
chroot "$CENTOSBOOTSTRAP_CHROOT" mount -t proc foo /proc
chroot "$CENTOSBOOTSTRAP_CHROOT" mount -t sysfs foo /sys

# install kernel
chroot "$CENTOSBOOTSTRAP_CHROOT" yum -y install kernel kernel-firmware abrt-addon-kerneloops kernel-devel dracut-kernel kernel-headers cpio device-mapper-multipath dmraid gzip kpartx lvm2 tar less device-mapper-event

# https://forums.aws.amazon.com/thread.jspa?messageID=301214&#301214
# https://forums.aws.amazon.com/thread.jspa?messageID=297856&#297856
chroot "$CENTOSBOOTSTRAP_CHROOT" depmod -ae -F /boot/System.map-"$CENTOS_KERNEL_VERSION"."$CENTOS_ARCH" "$CENTOS_KERNEL_VERSION"."$CENTOS_ARCH"
chroot "$CENTOSBOOTSTRAP_CHROOT" dracut --force '' "$CENTOS_KERNEL_VERSION"."$CENTOS_ARCH"

# install grub (is not required for ec2)
#chroot "$CENTOSBOOTSTRAP_CHROOT" yum -y install grub grubby grub diffutils redhat-logos

# install package management packages
chroot "$CENTOSBOOTSTRAP_CHROOT" yum -y install rpm elfutils-libelf rpm-libs sqlite yum-utils createrepo redhat-rpm-config pkgconfig

# install YUM (ensure extras)
chroot "$CENTOSBOOTSTRAP_CHROOT" yum -y install yum rpm-python yum-metadata-parser python-sqlite expat libxml2 python-urlgrabber m2crypto python-iniparse

# install extra packages
chroot "$CENTOSBOOTSTRAP_CHROOT" yum -y install \
rsyslog passwd openssh-server dhclient pcre info ncurses zlib gawk sysstat rpm-build glib2 mingetty \
ethtool coreutils libselinux libacl libattr pam audit-libs cracklib-dicts cracklib libsepol mcstrans \
libcap db4 openssl readline bzip2-libs gdbm findutils krb5-libs initscripts util-linux popt shadow-utils \
keyutils-libs iproute sysfsutils SysVinit net-tools module-init-tools e2fsprogs e2fsprogs-libs \
device-mapper psmisc procps libsysfs iputils mlocate logrotate postfix openssl openssh openssh-askpass \
openssh-clients gcc* bison flex compat-libstdc++-296 autoconf automake libtool compat-gcc-34-g77 \
rrdtool rrdtool-devel rrdtool-doc rrdtool-perl rrdtool-python rrdtool-ruby rrdtool-tcl libuser openldap cyrus-sasl-lib kbd usermode

# install extra base cli tools
chroot "$CENTOSBOOTSTRAP_CHROOT" yum -y install wget curl which screen grep lynx links zip unzip mutt sed

# install vcs packages
chroot "$CENTOSBOOTSTRAP_CHROOT" yum -y install cvs subversion git mercurial

# install text editors
chroot "$CENTOSBOOTSTRAP_CHROOT" yum -y install vim-minimal vim-enhanced vim-common nano joe

# install languages
chroot "$CENTOSBOOTSTRAP_CHROOT" yum -y install python ruby ruby-devel ruby-docs ruby-irb ruby-libs ruby-mode ruby-rdoc ruby-ri ruby-tcltk bash

# install rootfiles
chroot "$CENTOSBOOTSTRAP_CHROOT" yum -y install rootfiles

# install java (open,free)
yum -y install java java-1.6.0-openjdk

# install rightlink
chroot "$CENTOSBOOTSTRAP_CHROOT" userdel rightscale > /dev/null 2>&1 || true				# known bug: post does not remove rightscale user
chroot "$CENTOSBOOTSTRAP_CHROOT" rm -Rf /home/rightscale > /dev/null 2>&1 || true			# known bug: post does not remove rightscale /home
rm -Rfv "$CENTOSBOOTSTRAP_CHROOT/opt/rightscale/"											# known bug: post does not remove created files in /opt/rightscale
mkdir -p "$CENTOSBOOTSTRAP_CHROOT/etc/rightscale.d"
echo -n ec2 > "$CENTOSBOOTSTRAP_CHROOT/etc/rightscale.d/cloud"			# only ec2 at this time
chroot "$CENTOSBOOTSTRAP_CHROOT" yum -y install git lsb dig bind-utils git-core		# install deps manually
if (test "${RIGHTLINK_PKG_URL+defined}" && [ "$RIGHTLINK_PKG_URL" != '' ]); then
	rl_pkg_url="http://mirror.rightscale.com/rightlink/$RIGHTLINK_VERSION/centos/rightscale_$RIGHTLINK_VERSION-centos_5.6-$AMI_ARCH.rpm"
else
	rl_pkg_url="$RIGHTLINK_PKG_URL"
fi
chroot "$CENTOSBOOTSTRAP_CHROOT" rpm -iv --replacepkgs "$rl_pkg_url"


#
# RightScale yum repos mirror workarounds
# (TBR after fix)
# workaround for pending repos changes for centos6; effective disables addons and rightscale-epel by immutability (unfortunately the +i did not seem to be warranted, thus commenting out in repo_conf_generators)
#
## epel - make immutable (wrong filename from rightlink. epel-release-6-5.noarch.rpm uses epel.repo, epel-testing.repo. RS uses Epel.repo.)
touch "$CENTOSBOOTSTRAP_CHROOT/etc/yum.repos.d/Epel.repo"
:> "$CENTOSBOOTSTRAP_CHROOT/etc/yum.repos.d/Epel.repo"
chroot "$CENTOSBOOTSTRAP_CHROOT" chattr +i /etc/yum.repos.d/Epel.repo
## addons - make immutable
touch "$CENTOSBOOTSTRAP_CHROOT/etc/yum.repos.d/CentOS-addons.repo" || \
	( chroot "$CENTOSBOOTSTRAP_CHROOT" chattr -i /etc/yum.repos.d/CentOS-addons.repo && touch "$CENTOSBOOTSTRAP_CHROOT/etc/yum.repos.d/CentOS-addons.repo" )
:> "$CENTOSBOOTSTRAP_CHROOT/etc/yum.repos.d/CentOS-addons.repo"
chroot "$CENTOSBOOTSTRAP_CHROOT" chattr +i /etc/yum.repos.d/CentOS-addons.repo
## centosplus (repoconf managed filename)
touch "$CENTOSBOOTSTRAP_CHROOT/etc/yum.repos.d/CentOS-centosplus.repo"
:> "$CENTOSBOOTSTRAP_CHROOT/etc/yum.repos.d/CentOS-centosplus.repo"
chroot "$CENTOSBOOTSTRAP_CHROOT" chattr +i /etc/yum.repos.d/CentOS-centosplus.repo
## Rightscale-epel  (this should be fixed now)
#touch "$CENTOSBOOTSTRAP_CHROOT/etc/yum.repos.d/RightScale-epel.repo" || \
#	( chroot "$CENTOSBOOTSTRAP_CHROOT" chattr -i /etc/yum.repos.d/RightScale-epel.repo && touch "$CENTOSBOOTSTRAP_CHROOT/etc/yum.repos.d/RightScale-epel.repo" )
#:> "$CENTOSBOOTSTRAP_CHROOT/etc/yum.repos.d/RightScale-epel.repo"
#chroot "$CENTOSBOOTSTRAP_CHROOT" chattr +i /etc/yum.repos.d/RightScale-epel.repo
# fix for missing types.db
chroot "$CENTOSBOOTSTRAP_CHROOT" yum -y install collectd
if [ "$AMI_ARCH" = 'x86_64' ]; then
	chroot "$CENTOSBOOTSTRAP_CHROOT" cp -v /usr/share/collectd/types.db /usr/lib64/collectd/types.db
else
	chroot "$CENTOSBOOTSTRAP_CHROOT" cp -v /usr/share/collectd/types.db /usr/lib/collectd/types.db
fi
# comment out the repo conf gens anyway
cp -v "$RS_ATTACH_DIR/repo_conf_generators.rb" "$CENTOSBOOTSTRAP_CHROOT/opt/rightscale/right_link/repo_conf_generators/lib/repo_conf_generators.rb"
#cp -v "$RS_ATTACH_DIR/yum_conf_generators.rb" "$CENTOSBOOTSTRAP_CHROOT/opt/rightscale/right_link/repo_conf_generators/lib/repo_conf_generators/yum_conf_generators.rb"
#cp -v "$RS_ATTACH_DIR/rightscale_conf_generators.rb" "$CENTOSBOOTSTRAP_CHROOT	repo_conf_generators/rightscale_conf_generators.rb"

# update, upgrade packages & clean
chroot "$CENTOSBOOTSTRAP_CHROOT" yum -y update
chroot "$CENTOSBOOTSTRAP_CHROOT" yum -y upgrade
chroot "$CENTOSBOOTSTRAP_CHROOT" yum clean all

#
# Extra services
#
# install get ssh key service
wget http://rightscale-services.s3.amazonaws.com/scripts%2Finit%2Fgetsshkey.rc.debian.bash -O "$CENTOSBOOTSTRAP_CHROOT"/etc/init.d/getsshkey
chmod -v +x "$CENTOSBOOTSTRAP_CHROOT"/etc/init.d/getsshkey
chroot "$CENTOSBOOTSTRAP_CHROOT" chkconfig --add getsshkey
chroot "$CENTOSBOOTSTRAP_CHROOT" chkconfig --level 4 getsshkey

# ec2-run-user-data service to run user data scripts
# bug: /etc/rc3.d/S50ec2-run-user-data: line 53: tempfile: command not found (needs testing/porting)
#wget http://ec2ubuntu.googlecode.com/svn/trunk/etc/init.d/ec2-run-user-data -O "$CENTOSBOOTSTRAP_CHROOT"/etc/init.d/ec2-run-user-data
#chmod -v +x "$CENTOSBOOTSTRAP_CHROOT"/etc/init.d/ec2-run-user-data
#chroot "$CENTOSBOOTSTRAP_CHROOT" chkconfig --add ec2-run-user-data
#chroot "$CENTOSBOOTSTRAP_CHROOT" chkconfig --level 4 ec2-run-user-data

#
# Networking
#
mkdir -p "$CENTOSBOOTSTRAP_CHROOT/etc/sysconfig"
cat <<EOF> "$CENTOSBOOTSTRAP_CHROOT/etc/sysconfig/network"
NETWORKING=yes	
HOSTNAME=localhost.localdomain
EOF

mkdir -p "$CENTOSBOOTSTRAP_CHROOT/etc/sysconfig/network-scripts"
cat <<EOF> "$CENTOSBOOTSTRAP_CHROOT/etc/sysconfig/network-scripts/ifcfg-eth0"
DEVICE="eth0"
NM_CONTROLLED="no"
ONBOOT=yes
TYPE=Ethernet
BOOTPROTO=dhcp
DEFROUTE=yes
PEERDNS=yes
PEERROUTES=yes
IPV4_FAILURE_FATAL=yes
IPV6INIT=no
EOF

# disable IPV6
( grep 'NETWORKING_IPV6' "$CENTOSBOOTSTRAP_CHROOT/etc/sysconfig/network" && sed -i "s/NETWORKING_IPV6=yes/NETWORKING_IPV6=no/g" "$CENTOSBOOTSTRAP_CHROOT/etc/sysconfig/network" ) || \
	echo "NETWORKING_IPV6=no" >> "$CENTOSBOOTSTRAP_CHROOT/etc/sysconfig/network"
echo "install ipv6 /bin/true" > "$CENTOSBOOTSTRAP_CHROOT/etc/modprobe.d/disable-ipv6.conf"
echo "options ipv6 disable=1" >> "$CENTOSBOOTSTRAP_CHROOT/etc/modprobe.d/disable-ipv6.conf"
chroot "$CENTOSBOOTSTRAP_CHROOT" /sbin/chkconfig | grep ip6tables && chroot "$CENTOSBOOTSTRAP_CHROOT" /sbin/chkconfig ip6tables off

# show final packages
echo "============================="
echo "Packages installed in image:"
chroot "$CENTOSBOOTSTRAP_CHROOT" rpm -qa
echo "============================="

# show rc
echo "============================="
echo "Runtime Configuration:"
chroot "$CENTOSBOOTSTRAP_CHROOT" /sbin/chkconfig
echo "============================="

# show network interfaces
echo "============================="
echo "Network configurations:"
echo '/etc/sysconfig/network:'
cat "$CENTOSBOOTSTRAP_CHROOT/etc/sysconfig/network"
echo '/etc/sysconfig/network-scripts/ifcfg-lo:'
cat "$CENTOSBOOTSTRAP_CHROOT/etc/sysconfig/network-scripts/ifcfg-lo"
echo '/etc/sysconfig/network-scripts/ifcfg-eth0:'
cat "$CENTOSBOOTSTRAP_CHROOT/etc/sysconfig/network-scripts/ifcfg-eth0"
echo "============================="

echo 'Note: /etc/fstab is not yet configured.'
# show fstab
#echo "============================="
#echo "/etc/fstab in image:"
#cat "$CENTOSBOOTSTRAP_CHROOT/etc/fstab"
#echo "============================="

# test chroot shell login
#chroot "$CENTOSBOOTSTRAP_CHROOT" /bin/bash --login

chroot "$CENTOSBOOTSTRAP_CHROOT" umount /proc
chroot "$CENTOSBOOTSTRAP_CHROOT" umount /sys

echo 'Done.'
