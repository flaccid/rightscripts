#!/bin/bash -e

# RightScript: Set ulimit for open files
#
# Description: Sets/prints the ulimit for open files on the system.
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
#ULIMIT_USER
#ULIMIT_OPEN_FILES
#ULIMIT_REBOOT

: "${ULIMIT_USER:=root}"
: "${ULIMIT_OPEN_FILES:=4096}"
: "${ULIMIT_REBOOT:=yes}"

# display system ulimits
echo 'Current ulimits:'
echo '--'
ulimit -a   # see all the kernel parameters
echo '--'
echo
echo 'The current ulimit for open files is '"$(ulimit -n)"

# set ulimit test
echo 'Setting ulimit in current shell.'
ulimit -n "$ULIMIT_OPEN_FILES"				#  set the number open files (effectively a test as it only applies to this current shell)

if [ -e /etc/security/limits.conf ]; then
	echo 'Updating /etc/security/limits.conf.'
	if ! grep "$ULIMIT_USER               hard    nofile            $ULIMIT_OPEN_FILES" /etc/security/limits.conf; then
		echo 'Backing up current limits.conf.'
		cp -v /etc/security/limits.conf "/etc/security/limits.conf.backup.$(date +%s)"
		echo "$ULIMIT_USER               hard    nofile            $ULIMIT_OPEN_FILES" >> /etc/security/limits.conf
	fi
fi

if [ "$ULIMIT_USER" != "*" ]; then
	if ! grep "$ULIMIT_USER" /etc/passwd; then
		echo 'WARNING: User, $ULIMIT_USER does not exist!'
		echo "You may like to add this user first or check if you are specifying the correct user in the ULIMIT_USER input."
	else
		echo 'Adding ulimit to shell profiles for root.'
		IFS=: read -r _ _ _ _ _ home _ < <(getent passwd "$ULIMIT_USER")
		echo "ulimit -n $ULIMIT_OPEN_FILES" >> "$home/.bashrc"
		echo "ulimit -n $ULIMIT_OPEN_FILES" >> "$home/.bash_profile"
	fi
fi

if [ "$ULIMIT_REBOOT" ]; then
	echo 'Backgrounding reboot command (60 seconds)'
	exec $(sleep 60; reboot <&- >&- 2>&- )&
else
	echo 'IMPORTANT: A system reboot is required to effect changes.'
fi

echo 'Done.'