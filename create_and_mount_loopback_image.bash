#!/bin/bash -e

# RightScript: Create and mount loopback image
#
# Description: Creates and mounts an image for loopback mounting.
#
# Inputs:
# LOOPBACK_IMAGE_NAME	
## LOOPBACK_IMAGE_SIZE
# LOOPBACK_IMAGE_DEST		
# LOOPBACK_IMAGE_MOUNTPOINT		
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

image_name=`eval echo $LOOPBACK_IMAGE_NAME`
#image_size="$LOOPBACK_IMAGE_SIZE"
image_dest=`eval echo $LOOPBACK_IMAGE_DEST`
image_mountpoint=`eval echo $LOOPBACK_IMAGE_MOUNTPOINT`

#/mnt/image-bundles/"$image_name"

# create and change directories to the image destination
mkdir -pv "$image_dest" || true
cd "$image_dest"

# Create an empty file for the image
echo 'Creating image, '"$image_name"'.'
#dd if=/dev/zero of="$image_name".img bs=1M count="$image_size"
dd if=/dev/zero of="$image_name".img bs=1000 count=0 seek=$((1000*1000*8))	# create 8GB image, fast

# Create an ext3 filesystem inside the image file.
echo 'Creating filesystem in image.'
/sbin/mke2fs -F -j -L / "$image_dest"/"$image_name".img

#Mount the image file using the loop-back option, allowing you to treat the image file as if it was a standard disk drive.
echo 'Mounting image.'
mkdir -pv "$image_mountpoint" || true
mount -o loop "$image_dest"/"$image_name".img "$image_mountpoint"

echo 'Done.'