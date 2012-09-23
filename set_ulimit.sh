#!/bin/bash

# RightScript: Set ulimit for open files
#
# Description: Sets or prints ulimit on the system.
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

# Inputs:
#ULIMIT_OPEN_FILES
#ULIMIT_REBOOT

# display system ulimits
echo 'Current ulimits:'
echo '--'
ulimit -a   # see all the kernel parameters
echo '--'
echo
echo 'The current ulimit for open files is '"$(ulimit -n)"

# set ulimit test
ulimit -n "$ULIMIT_OPEN_FILES"				#  set the number open files (effectively a test as it only applies to this current shell)

# update 

echo 'IMPORTANT: A system reboot is required.'

if [ "$ULIMIT_REBOOT" ]; then
	echo 'Backgrounding reboot command (60 seconds)'
	exec $(sleep 60; reboot <&- >&- 2>&- )&
fi

echo 'Done.'