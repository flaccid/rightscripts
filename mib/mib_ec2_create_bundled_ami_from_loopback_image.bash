#!/bin/bash -e

# RightScript: Create bundled AMI from loopback image
#
# Description: Creates a bundled AMI from a loopback image.
# 
# Inputs:
# AMI_BUNDLE_IMAGE
# AMI_BUNDLE_ARCH
# AMI_BUNDLE_IMAGE				Create a bundled AMI from an image (bool; true | false;default: false)
# AMI_BUNDLE_BLOCKDEV_MAPPING	Default block-device-mapping scheme with which to launch the AMI, e.g. --block-device-mapping ami=sda1,root=/dev/sda1,ephemeral0=sda2,swap=sda3

# AMI_BUNDLE_DEST_DIR			The directory in which to create the bundle, e.g. /mnt/debootstrap-root/tmp/bundles (text; default /tmp)
# AMI_BUNDLE_PREFIX				The filename prefix for bundled AMI files (text; default: image)
# AMI_BUNDLE_KERNEL_ID			The ID of the kernel to select
# AMI_RAMDISK_ID				The ID of the RAM disk to select
# LOOPBACK_IMAGE_NAME	
# LOOPBACK_IMAGE_DEST		
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

# source root's profile
source /root/.profile

aws_account_number="$AWS_ACCOUNT_NUMBER"
image_name=`eval echo $LOOPBACK_IMAGE_NAME`
image_dest=`eval echo $LOOPBACK_IMAGE_DEST`

ec2_bundle_dest_dir=`eval echo $AMI_BUNDLE_DEST_DIR`
ec2_bundle_image_file=`eval echo $LOOPBACK_IMAGE_DEST/$LOOPBACK_IMAGE_NAME.img`
ec2_bundle_prefix=`eval echo $AMI_BUNDLE_PREFIX`
ec2_bundle_arch="$AMI_BUNDLE_ARCH"
if [ "$AMI_BUNDLE_KERNEL_ID" ]; then
	ec2_bundle_kernel="--kernel $AMI_BUNDLE_KERNEL_ID"
fi
if [ "$AMI_BUNDLE_RAMDISK_ID" ]; then
	ec2_bundle_ramdisk=="--ramdisk $AMI_BUNDLE_RAMDISK_ID"
fi

echo
echo 'Bundled AMI details:'
echo '--'
echo 'Source image:             '"$ec2_bundle_image_file (`ls -lah $ec2_bundle_image_file | awk '{ print $5}'`)"
echo 'Prefix:                   '"$ec2_bundle_prefix"
echo 'Architecture:             '"$ec2_bundle_arch"
echo 'Destination directory:    '"$ec2_bundle_dest_dir"
echo 'AWS Account Number:       '"$aws_account_number"
echo 'AWS Certificate file:     '"$AWS_CERT_FILE"
echo 'AWS Pivate Key file:      '"$AWS_PRIVATE_KEY_FILE"
if [ "$AMI_BUNDLE_KERNEL_ID" ]; then
	echo "Kernel:       $AMI_BUNDLE_KERNEL_ID"
fi
if [ "$AMI_BUNDLE_RAMDISK_ID" ]; then
	echo "Ramdisk:       $AMI_BUNDLE_RAMDISK_ID"
fi
echo '--'
echo

#
# Bundle the loopback image with ec2-bundle-image
#
if [ "$AMI_BUNDLE_IMAGE" = 'true' ]; then
	mkdir -pv "$ec2_bundle_dest_dir" || true
	echo 'Bundling image with ec2-bundle-image.'
	ec2-bundle-image \
	-k "$AWS_PRIVATE_KEY_FILE" \
	-c "$AWS_CERT_FILE" \
	--image "$ec2_bundle_image_file" \
	--prefix "$ec2_bundle_prefix" \
	--user "$AWS_ACCOUNT_NUMBER" \
	--destination "$ec2_bundle_dest_dir" \
	--arch "$ec2_bundle_arch" \
	$ec2_bundle_kernel \
	$ec2_bundle_ramdisk
else
	echo 'AMI_BUNDLE_IMAGE set to false, skipping bundling.'
fi

echo 'Done.'