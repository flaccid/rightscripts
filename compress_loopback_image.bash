#!/bin/bash -e

# RightScript: Compress loopback image
#
# Description: Compresses a loopback image into a tar.gz
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
image_dest=`eval echo $LOOPBACK_IMAGE_DEST`
# generally use /mnt/image-bundles/"$image_name"

# create and change directories to the image destination
mkdir -p "$image_dest"
cd "$image_dest"

# compress file with tar
echo "Compressing $image_name.img, please wait..."
tar cvzf "$image_name.img.tar.gz" "$image_name.img"

echo 'Done.'