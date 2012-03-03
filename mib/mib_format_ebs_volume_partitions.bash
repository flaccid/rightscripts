#!/bin/bash -ex

# RightScript: MIB: Format EBS volume partitions
#
# Description: Formats the two partitions on the EBS volume.
#
# Inputs:
# MIB_EBS_IMAGE_VOL_DEVICE
# MIB_EBS_IMAGE_ROOT_FSTYPE
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
: ${MIB_EBS_IMAGE_VOL_DEVICE:=/dev/sdd}
: ${MIB_EBS_IMAGE_ROOT_FSTYPE:=ext3}
: ${MIB_EBS_IMAGE_ROOT_LABEL:=/}

# Format partitions (forces by default)

echo "y" | mkfs.ext2 -F "$MIB_EBS_IMAGE_VOL_DEVICE"1		# /boot

# swap resides on the 3rd and last partition
case "$MIB_EBS_IMAGE_ROOT_FSTYPE" in
    xfs)
                      apt-get -y install xfsprogs
                      echo "y" | mkfs.xfs -f "$MIB_EBS_IMAGE_VOL_DEVICE"2		# / (root fs)
                      ;;
    ext2|ext3|ext4)  
                      echo "y" | mkfs."$MIB_EBS_IMAGE_ROOT_FSTYPE" -L "$MIB_EBS_IMAGE_ROOT_LABEL" -F "$MIB_EBS_IMAGE_VOL_DEVICE"2		# / (root fs)
                      ;;
     *)
                      echo "Unsupported fs type."
                      exit 1
                      ;;
esac

echo "$MIB_EBS_IMAGE_VOL_DEVICE"'2 disklabel: '`e2label "$MIB_EBS_IMAGE_VOL_DEVICE"2`

echo 'Done.'