#!/bin/bash -e

# RightScript: Centosbootstrap configure GRUB menu.lst
#
# Description: Configures a menu.lst for legacy GRUB from the kernels installed in a Centosbootstrap/boot folder.
# Currently only up two kernels are added.
#
# Inputs:
# CENTOSBOOTSTRAP_CHROOT				e.g. /mnt/mib.master
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

# defaults
: ${CENTOS_ARCH:=`uname -m`}
: ${CENTOSBOOTSTRAP_CHROOT:=/mnt/mib.master}
: ${CENTOS_KERNEL_VERSION:=2.6.32-220.4.2.el6.centos.plus}

# evaluate inputs
export CENTOSBOOTSTRAP_CHROOT=`eval echo $CENTOSBOOTSTRAP_CHROOT`

# make /boot/grub folder if not existing (grub install is not required)
mkdir -p "$CENTOSBOOTSTRAP_CHROOT"/boot/grub

# backup menu.lst if exists
if [ -e "$CENTOSBOOTSTRAP_CHROOT"/boot/grub/menu.lst ]; then
	echo 'Backing up existing menu.lst.'
	mv -v "$CENTOSBOOTSTRAP_CHROOT"/boot/grub/menu.lst "$CENTOSBOOTSTRAP_CHROOT"/boot/grub/menu.lst.backup-build
fi

kernel="$CENTOS_KERNEL_VERSION.$CENTOS_ARCH"
boot_arch="$CENTOS_ARCH"
boot_title="CentOS release 6.2 (Final) $boot_arch, with $kernel"
kernel_params="ro console=hvc0 crashkernel=auto SYSFONT=latarcyrheb-sun16 LANG=en_US.UTF-8 KEYTABLE=de-latin1-nodeadkeys"
master_root_dev="hd0"
master_kernel_root="/dev/xvde1"
ebs_root_dev="hd0,0"
ebs_kernel_root="/dev/xvde1"

# Create /boot/grub/menu.lst with header and options only first
cp -v "$ATTACH_DIR"/menu.lst-default_options.txt "$CENTOSBOOTSTRAP_CHROOT"/boot/grub/menu.lst

cat >> "$CENTOSBOOTSTRAP_CHROOT"/boot/grub/device.map <<EOF
(hd0)     /dev/sda

EOF

#
# menu.list (master)
#
echo >> "$CENTOSBOOTSTRAP_CHROOT"/boot/grub/menu.lst        # ensure blank line
cat >> "$CENTOSBOOTSTRAP_CHROOT"/boot/grub/menu.lst <<EOF

title       $boot_title
root        ($master_root_dev)
kernel      /boot/vmlinuz-$kernel root=LABEL=/ $kernel_params
initrd      /boot/initramfs-$kernel.img

EOF

#
# menu.lst (EBS)
#
# copy master menu.lst to ebs volume
cp -v "$CENTOSBOOTSTRAP_CHROOT"/boot/grub/menu.lst /mnt/mib-ebs-root/boot/grub/menu.lst
# change the root device and kernel root in ebs menu.lst
sed -i "s%$master_root_dev%$ebs_root_dev%" /mnt/mib-ebs-root/boot/grub/menu.lst
sed -i "s%$master_kernel_root%$ebs_kernel_root%" /mnt/mib-ebs-root/boot/grub/menu.lst

echo 'Showing files.'
echo
echo 'instance-store AMI (master) menu.lst:'
echo '--'
cat "$CENTOSBOOTSTRAP_CHROOT"/boot/grub/menu.lst
echo '--'
echo
echo 'EBS AMI menu.lst:'
echo '--'
cat /mnt/mib-ebs-root/boot/grub/menu.lst
echo '--'
echo

echo 'Done.'