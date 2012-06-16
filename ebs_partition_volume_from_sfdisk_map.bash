#!/bin/bash -e

# RightScript: EBS partition volume from sfdisk map
#
# Description: Partitions an EBS volume from a map exported from sfdisk. System needs the linux-util package.
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

# 8GB
cat <<EOF> /tmp/partition.ebs.disk.sfdisk
unit: sectors

/dev/xvdq1 : start=       63, size= 16771797, Id=83
/dev/xvdq2 : start=        0, size=        0, Id= 0
/dev/xvdq3 : start=        0, size=        0, Id= 0
/dev/xvdq4 : start=        0, size=        0, Id= 0
EOF

# apply map to new vol:
sfdisk "$EBS_SFDISK_IMAGE_VOL_DEVICE" < /tmp/partition.ebs.disk.sfdisk

# mark partition as bootable/active
sfdisk -A "$EBS_SFDISK_IMAGE_VOL_DEVICE" 1

echo 'Done.'