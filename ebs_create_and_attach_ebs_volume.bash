#! /bin/bash -e

# RightScript: Create and attach EBS volume
#
# Description: Creates and attaches an EBS volume.
#
# Inputs:
# EBS_VOLUME_SIZE
# EBS_VOLUME_REGION
# EBS_VOLUME_AVAILABILITY_ZONE
# EBS_VOLUME_DEVICE
# EBS_VOLUME_INSTANCE_ID
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

# turn on extglob
# "Extended globs" (shopt -s extglob) allow you to say things like "all files that do not end in .jpg". See http://mywiki.wooledge.org/glob
shopt -s extglob

# defaults
: ${EBS_VOLUME_SIZE:=1}
: ${EBS_VOLUME_DEVICE:=/dev/sde}
: "${EBS_VOLUME_AVAILABILITY_ZONE:=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)}"
: ${EBS_VOLUME_REGION:="${EBS_VOLUME_AVAILABILITY_ZONE%%*([![:digit:]])}"}
: "${EBS_VOLUME_INSTANCE_ID:=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)}"

# hax: comment out mesg in .profile as command is not compatible with non tty
if grep mesg ~/.profile > /dev/null 2>&1; then
   	sed -i -e 's/mesg/#mesg/g' ~/.profile
fi

# include shell profile(s)
if [ -e "$HOME/.profile" ]
    then source "$HOME/.profile"
else
   [ -e "$HOME/.bashrc" ] && source "$HOME/.bashrc"
fi

#echo "Debug: EC2_HOME=$EC2_HOME"

echo 'Creating new '"$EBS_VOLUME_SIZE"'GB EBS volume.'
vol_out=$(ec2-create-volume --region "$EBS_VOLUME_REGION" --size "$EBS_VOLUME_SIZE" --availability-zone "$EBS_VOLUME_AVAILABILITY_ZONE")
read -r _ vol_id _ <<< "$vol_out"
echo 'New volume: '"$vol_id"

echo 'Waiting for volume to be ready.'
while [ 1 ]; do 
	vol_stat_out=$(ec2-describe-volumes --region "$EBS_VOLUME_REGION" "$vol_id" --filter status=available)
	if [[ $vol_stat_out ]]; then
		echo "$vol_id" is ready.
		echo "$vol_stat_out"
		break;
	fi
	sleep 1
done

# xen kernel device support
EBS_VOLUME_DEVICE=${EBS_VOLUME_DEVICE//xv/s}

echo 'Attaching volume to '"$EBS_VOLUME_DEVICE"
attach_out=$(ec2-attach-volume --region "$EBS_VOLUME_REGION" "$vol_id" -i "$EBS_VOLUME_INSTANCE_ID" -d "$EBS_VOLUME_DEVICE")
echo "$attach_out"

# symlink for < rightlink 5.7
[ ! -e /var/spool/cloud ] && ln -sfv /var/spool/ec2 /var/spool/cloud

echo 'Waiting for volume to be attached.'
while [ 1 ]; do 
	vol_stat_out=$(ec2-describe-volumes --region "$EBS_VOLUME_REGION" "$vol_id" --filter attachment.status=attached)
	if [[ $vol_stat_out ]]; then
		echo "$vol_id" is attached.
                echo "$vol_id" > /var/spool/cloud/meta-data/ebs-vol-id
		echo "$vol_stat_out"
		break;
	fi
	sleep 1
done

echo 'Done.'