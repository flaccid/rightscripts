#!/bin/bash -ex

# RightScript: MIB: Convert raw image to VHD image
#
# Description: Converts a .img (dd) to a .vhd
#
# Inputs:
# MIB_RAW_IMAGE
# MIB_VHD_IMAGE
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
: ${MIB_RAW_IMAGE:=/mnt/machine-images/mib_master.img}
: ${MIB_VHD_IMAGE:=/mnt/machine-images/mib_master.vhd}

apt-get -y install virtualbox-ose

VBoxManage convertfromraw "$MIB_RAW_IMAGE" "$MIB_VHD_IMAGE" --format VHD

echo 'Done.'