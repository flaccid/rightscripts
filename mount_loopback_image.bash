#!/bin/bash -e

# RightScript: Mount loopback image
#
# Description: Mounts a loopback image.
#
# Inputs:
# LOOPBACK_IMAGE_NAME	
# LOOPBACK_IMAGE_LOCATION
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
image_location=`eval echo $LOOPBACK_IMAGE_LOCATION`
image_mountpoint=`eval echo $LOOPBACK_IMAGE_MOUNTPOINT`

mkdir -p "$image_mountpoint"

# Mount the image file using the loop-back option, allowing you to treat the image file as if it was a standard disk drive.
mount -o loop "$image_location/$image_name".img "$image_mountpoint"

echo 'Done.'