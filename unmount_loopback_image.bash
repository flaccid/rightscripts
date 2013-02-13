#!/bin/bash -e

# RightScript: Unmount loopback image
#
# Description: Unmounts the loopback image.
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

loopback_mountpoint=/mnt/`eval echo $LOOPBACK_IMAGE_NAME`
if mount | grep "on $loopback_mountpoint"; then
	echo "Unmounting $loopback_mountpoint"
	umount -l "$loopback_mountpoint"
else
	echo "$loopback_mountpoint" not mounted, so not unmounting.
fi

echo 'Done.'