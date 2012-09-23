#!/bin/bash -e

# RightScript: Debootstrap configure GRUB menu.lst
#
# Description: Configures a menu.lst for legacy GRUB from the kernels installed in a debootstrap/boot folder.
# Currently only up two kernels are added.
#
# Inputs:
# DEBOOTSTRAP_KERNEL_MAJOR_VERSION		e.g. 2.6
# DEBOOTSTRAP_TARGET_DIR				e.g. /mnt/debootstrap
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
: ${DEBOOTSTRAP_KERNEL_MAJOR_VERSION:=2.6}
: ${DEBOOTSTRAP_KERNEL_MAJOR_VERSION:=/}      # can be used on local system

# evaluate inputs
export DEBOOTSTRAP_TARGET_DIR=`eval echo $DEBOOTSTRAP_TARGET_DIR`

mv="$DEBOOTSTRAP_KERNEL_MAJOR_VERSION"
kernel_images="$(ls "$DEBOOTSTRAP_TARGET_DIR"/boot | grep initrd.img | sed -e 's/initrd.img-//g')"
kernel=$(echo $kernel_images | awk '{ print $1 }')
kernel_extra=$(echo $kernel_images | awk '{ print $2 }')
boot_arch=$(chroot "$DEBOOTSTRAP_TARGET_DIR" dpkg --print-architecture)
boot_title="$(chroot "$DEBOOTSTRAP_TARGET_DIR" lsb_release -ds) $boot_arch, with $kernel"
kernel_params="ro"
master_root_dev="hd0"
master_kernel_root="/dev/xvda1"
ebs_root_dev="hd0,0"
ebs_kernel_root="/dev/xvda1"

# make /boot/grub folder if not existing (grub install is not required)
mkdir -p "$DEBOOTSTRAP_TARGET_DIR"/boot/grub
mkdir -p /mnt/mib-ebs-root/boot/grub

# backup menu.lst if exists
if [ -e "$DEBOOTSTRAP_TARGET_DIR"/boot/grub/menu.lst ]; then
	echo 'Backing up existing menu.lst.'
	mv -v "$DEBOOTSTRAP_TARGET_DIR"/boot/grub/menu.lst "$DEBOOTSTRAP_TARGET_DIR"/boot/grub/menu.lst.backup-build
fi

# Create /boot/grub/menu.lst with header and options only first
cp -v "$ATTACH_DIR"/menu.lst-default_options.txt "$DEBOOTSTRAP_TARGET_DIR"/boot/grub/menu.lst

# Add master /boot/grub/menu.lst to debootstrap target directory
echo >> "$DEBOOTSTRAP_TARGET_DIR"/boot/grub/menu.lst        # ensure blank line
cat >> "$DEBOOTSTRAP_TARGET_DIR"/boot/grub/menu.lst <<EOF

title       $boot_title
root        ($master_root_dev)
kernel      /boot/vmlinuz-$kernel root=$master_kernel_root $kernel_params
initrd      /boot/initrd.img-$kernel

EOF

# add in an extra kernel if specified
if [[ $kernel_extra ]]; then
    boot_title="$(chroot "$DEBOOTSTRAP_TARGET_DIR" lsb_release -ds) $boot_arch, with $kernel_extra"
cat >> "$DEBOOTSTRAP_TARGET_DIR"/boot/grub/menu.lst <<EOF
title       $boot_title
root        ($master_root_dev)
kernel      /boot/vmlinuz-$kernel_extra root=$master_kernel_root $kernel_params
initrd      /boot/initrd.img-$kernel_extra
EOF
fi

# copy master menu.lst to ebs volume
cp -v "$DEBOOTSTRAP_TARGET_DIR"/boot/grub/menu.lst /mnt/mib-ebs-root/boot/grub/menu.lst

# change the root device and kernel root in ebs menu.lst
sed -i "s%$master_root_dev%$ebs_root_dev%" /mnt/mib-ebs-root/boot/grub/menu.lst
sed -i "s%$master_kernel_root%$ebs_kernel_root%" /mnt/mib-ebs-root/boot/grub/menu.lst

# show the configs
echo 'Showing files.'
echo
echo '(master) menu.lst:'
echo '--'
cat "$DEBOOTSTRAP_TARGET_DIR"/boot/grub/menu.lst
echo '--'
echo
echo '(EBS) menu.lst:'
echo '--'
cat /mnt/mib-ebs-root/boot/grub/menu.lst
echo '--'
echo

echo 'Done.'