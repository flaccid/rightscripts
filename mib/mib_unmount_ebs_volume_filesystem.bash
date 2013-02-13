#!/bin/bash -ex

# RightScript: MIB: Unmount EBS volume filesystems
#
# Description: Unmounts the filesystems from the EBS volume.
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

if mount | grep "$MIB_EBS_IMAGE_VOL_DEVICE"1; then
     umount -v /mnt/mib-ebs-root	# /
fi

echo 'Done.'