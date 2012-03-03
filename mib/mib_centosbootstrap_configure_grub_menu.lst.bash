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
: ${CENTOSBOOTSTRAP_CHROOT:=/mnt/mib.master}

# evaluate inputs
export CENTOSBOOTSTRAP_CHROOT=`eval echo $CENTOSBOOTSTRAP_CHROOT`

# make /boot/grub folder if not existing (grub install is not required)
mkdir -p "$CENTOSBOOTSTRAP_CHROOT"/boot/grub
mkdir -p /mnt/mib-ebs-boot/boot/grub

# backup menu.lst if exists
if [ -e "$CENTOSBOOTSTRAP_CHROOT"/boot/grub/menu.lst ]; then
	echo 'Backing up existing menu.lst.'
	mv -v "$CENTOSBOOTSTRAP_CHROOT"/boot/grub/menu.lst "$CENTOSBOOTSTRAP_CHROOT"/boot/grub/menu.lst.backup-build
fi

# ensure boot mountpoint exists root partition
mkdir -p /mnt/mib-ebs-root/mnt/boot

# remove boot directory from root (if exists)
if [ -e /mnt/mib-ebs-root/boot ]; then
	echo 'Removing existing boot directory from root partition'
	rm -Rfv /mnt/mib-ebs-root/boot
fi

# symlinked boot fs mountpoint to /boot
chroot /mnt/mib-ebs-root ln -svf /mnt/boot/boot /

kernel="2.6.32-71.29.1.el6.$CENTOS_ARCH"
boot_arch="$CENTOS_ARCH"
boot_title="CentOS Linux release 6.0 (Final) $boot_arch, with $kernel"
kernel_params="ro console=hvc0 crashkernel=auto SYSFONT=latarcyrheb-sun16 LANG=en_US.UTF-8 KEYTABLE=de-latin1-nodeadkeys"
master_root_dev="hd0"
master_kernel_root="/dev/xvda1"
ebs_root_dev="hd0,0"
ebs_kernel_root="/dev/xvda2"

# Create /boot/grub/menu.lst with header and options only first
cp -v "$ATTACH_DIR"/menu.lst-default_options.txt "$CENTOSBOOTSTRAP_CHROOT"/boot/grub/menu.lst

#
# menu.list (master)
#
echo >> "$CENTOSBOOTSTRAP_CHROOT"/boot/grub/menu.lst        # ensure blank line
cat >> "$CENTOSBOOTSTRAP_CHROOT"/boot/grub/menu.lst <<EOF

title       $boot_title
root        ($master_root_dev)
kernel      /boot/vmlinuz-2.6.32-71.29.1.el6.$CENTOS_ARCH root=$master_kernel_root $kernel_params
initrd      /boot/initramfs-2.6.32-71.29.1.el6.$CENTOS_ARCH.img

EOF

cat >> "$CENTOSBOOTSTRAP_CHROOT"/boot/grub/device.map <<EOF
(hd0)     /dev/sda

EOF

#
# menu.lst (EBS)
#
# copy master menu.lst to ebs volume
cp -v "$CENTOSBOOTSTRAP_CHROOT"/boot/grub/menu.lst /mnt/mib-ebs-boot/boot/grub/menu.lst

# change the root device and kernel root in ebs menu.lst
sed -i "s%$master_root_dev%$ebs_root_dev%" /mnt/mib-ebs-boot/boot/grub/menu.lst
sed -i "s%$master_kernel_root%$ebs_kernel_root%" /mnt/mib-ebs-boot/boot/grub/menu.lst

echo 'Showing files.'
echo
echo 'instance-store AMI (master) menu.lst:'
echo '--'
cat "$CENTOSBOOTSTRAP_CHROOT"/boot/grub/menu.lst
echo '--'
echo
echo 'EBS AMI menu.lst:'
echo '--'
cat /mnt/mib-ebs-boot/boot/grub/menu.lst
echo '--'
echo

echo 'Done.'