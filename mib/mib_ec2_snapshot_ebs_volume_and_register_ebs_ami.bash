#!/bin/bash -e

# RightScript: EC2 snapshot EBS volume and register EBS AMI
#
# Description: Snapshots an EBS volume and registers the snapshot as an AMI.
#
# Inputs:
# AMI_NAME
# AMI_DESCRIPTION
# AWS_CERT_FILE
# AWS_PRIVATE_KEY_FILE
# AMI_REGION
# AMI_ARCH
# AMI_EBS_KERNEL_ID
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

# US-East-1
# aki-825ea7eb ec2-public-images/pv-grub-hd0_1.02-x86_64.gz.manifest.xml
# aki-805ea7e9 ec2-public-images/pv-grub-hd0_1.02-i386.gz.manifest.xml
# aki-8e5ea7e7 ec2-public-images/pv-grub-hd00_1.02-x86_64.gz.manifest.xml
# aki-525ea73b ec2-public-images/pv-grub-hd00_1.02-i386.gz.manifest.xml

# US-West-1
# aki-8d396bc8 ec2-public-images-us-west-1/pv-grub-hd0_1.02-x86_64.gz.manifest.xml
# aki-83396bc6 ec2-public-images-us-west-1/pv-grub-hd0_1.02-i386.gz.manifest.xml
# aki-81396bc4 ec2-public-images-us-west-1/pv-grub-hd00_1.02-x86_64.gz.manifest.xml
# aki-87396bc2 ec2-public-images-us-west-1/pv-grub-hd00_1.02-i386.gz.manifest.xml

# US-West-2
# aki-c0e26ff0 ec2-public-images-us-west-2/pv-grub-hd00_1.02-i386.gz.manifest.xml
# aki-94e26fa4 ec2-public-images-us-west-2/pv-grub-hd00_1.02-x86_64.gz.manifest.xml
# aki-c2e26ff2 ec2-public-images-us-west-2/pv-grub-hd0_1.02-i386.gz.manifest.xml
# aki-98e26fa8 ec2-public-images-us-west-2/pv-grub-hd0_1.02-x86_64.gz.manifest.xml

# EU-West-1
# aki-62695816 ec2-public-images-eu/pv-grub-hd0_1.02-x86_64.gz.manifest.xml
# aki-64695810 ec2-public-images-eu/pv-grub-hd0_1.02-i386.gz.manifest.xml
# aki-60695814 ec2-public-images-eu/pv-grub-hd00_1.02-x86_64.gz.manifest.xml
# aki-8a6657fe ec2-public-images-eu/pv-grub-hd00_1.02-i386.gz.manifest.xml

# AP-SouthEast-1
# aki-aa225af8 ec2-public-images-ap-southeast-1/pv-grub-hd0_1.02-x86_64.gz.manifest.xml
# aki-a4225af6 ec2-public-images-ap-southeast-1/pv-grub-hd0_1.02-i386.gz.manifest.xml
# aki-a6225af4 ec2-public-images-ap-southeast-1/pv-grub-hd00_1.02-x86_64.gz.manifest.xml
# aki-a0225af2 ec2-public-images-ap-southeast-1/pv-grub-hd00_1.02-i386.gz.manifest.xml

# AP-NorthEast-1
# aki-ee5df7ef ec2-public-images-ap-northeast-1/pv-grub-hd0_1.02-x86_64.gz.manifest.xml
# aki-ec5df7ed ec2-public-images-ap-northeast-1/pv-grub-hd0_1.02-i386.gz.manifest.xml
# aki-ea5df7eb ec2-public-images-ap-northeast-1/pv-grub-hd00_1.02-x86_64.gz.manifest.xml
# aki-e85df7e9 ec2-public-images-ap-northeast-1/pv-grub-hd00_1.02-i386.gz.manifest.xml

# SA-East-1
# aki-cc3ce3d1 ec2-public-images-sa-east-1/pv-grub-hd0_1.02-x86_64.gz.manifest.xml
# aki-bc3ce3a1 ec2-public-images-sa-east-1/pv-grub-hd0_1.02-i386.gz.manifest.xml
# aki-d23ce3cf ec2-public-images-sa-east-1/pv-grub-hd00_1.02-x86_64.gz.manifest.xml
# aki-823ce39f ec2-public-images-sa-east-1/pv-grub-hd00_1.02-i386.gz.manifest.xml

# source root's profile
source /root/.profile

# set local variables for the AMI registration
aws_cert="$AWS_CERT_FILE"
aws_key="$AWS_PRIVATE_KEY_FILE"

# AMI metadata
ami_name=`eval echo $AMI_NAME`'_ebs'
ami_desc=`eval echo $AMI_DESCRIPTION`' EBS'
ami_region="$AMI_REGION"
ami_kernel_id="$AMI_EBS_KERNEL_ID"
ami_arch="$AMI_ARCH"

# get volume ID from instance's cloud cache
ebs_vol=`cat /var/spool/cloud/meta-data/ebs-vol-id`

# create snapshot and get snap ID
snap_out=$(ec2-create-snapshot \
	--private-key "$aws_key" \
	--cert "$aws_cert" \
	--description "$ami_desc" \
	--region "$ami_region" \
	"$ebs_vol")

# assign snap ID
snap_id=`echo -n $snap_out | awk '{ print $2 }'`

# Show AMI details for registration
echo 'AMI details:'
echo '--'
echo 'Name:         '"$ami_name"
echo 'Description:  '"$ami_desc"
echo 'Region:       '"$ami_region"
echo 'Snapshot ID:  '"$snap_id"
echo 'Kernel ID:    '"$ami_kernel_id"
echo 'Architecture: '"$ami_arch"
echo '--'

# loop and wait for snapshot to become available
echo 'Waiting for snapshot to complete...'
while [ 1 ]; do 
	snap_status=$(ec2-describe-snapshots \
	 	--private-key "$aws_key" \
		--cert "$aws_cert" \
		--region "$ami_region" \
		"$snap_id")
	if `echo $snap_status | grep -q "completed"` ; then
		break;
	else
		echo '.'
	fi
	sleep 1
done
echo 'EBS snapshot completed; ready for AMI registration.'

# Register EBS snapshot as an AMI
echo 'Registering EBS AMI.'
register_out=$(ec2-register \
	--private-key "$aws_key" \
	--cert "$aws_cert" \
	--name "$ami_name" \
	--description "$ami_desc" \
	--region "$ami_region" \
	--kernel "$ami_kernel_id" \
	--architecture "$ami_arch" \
	--block-device-mapping /dev/sda="$snap_id"::true \
	--block-device-mapping /dev/sdb=ephemeral0 \
	--block-device-mapping /dev/sdc=ephemeral1 \
	--block-device-mapping /dev/sdd=ephemeral2 \
	--block-device-mapping /dev/sde=ephemeral3)

ami_id=`echo -n $register_out | awk '{ print $2 }'`

echo "$ami_id"' successfully registered.'
echo "$ami_id" >> "$TAG_AMI_DB"
echo 'AMI registered: '"$register_out" | mail -s 'New EBS AMI registered.' "$AMI_REGISTER_NOTIFY_EMAIL"
echo 'Done.'