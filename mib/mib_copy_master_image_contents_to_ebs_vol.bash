#!/bin/sh -e

# RightScript: MIB: Copy master image contents to EBS volume
#
# Description: Copies files from the mountpoint of the loopback image to the mounted EBS volume location.
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
image_mountpoint=`eval echo $LOOPBACK_IMAGE_MOUNTPOINT`
image_location=`eval echo $LOOPBACK_IMAGE_LOCATION`

# dd is too slow in EC2 on EBS volumes
#dd if="$image_location/$image_name.img" of=/dev/sdl

# rsync image contents to mounted EBS volume
echo 'Copying image contents to /mnt/mib-ebs-root, Please wait...'
rsync -az "$image_mountpoint"/ /mnt/mib-ebs-root

echo 'Done.'