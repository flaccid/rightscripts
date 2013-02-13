#!/bin/bash -e

# RightScript: EC2 register S3 AMI
#
# Description: Registers an instance-store AMI in S3.
#
# Inputs:
# AMI_NAME				The name of the AMI that was provided during image creation e.g. 'rightimage_debian_squeeze_i386_server_v5.4.6_'`date +%Y%m%d`'.1'
# AMI_DESCRIPTION		The description of the AMI e.g. 'RightImage Debian squeeze \(testing\) i386 Server v5.4.6 \('`date`'\)'
# AMI_MANIFEST			Full path to your AMI manifest in Amazon S3 storage, e.g. "$AMI_BUNDLE_UPLOAD_S3_BUCKET"'/rightimage_debian_squeeze_i386_v5.4.6_'`date +%Y%m%d`'.1.manifest.xml'
# AMI_REGISTER			Register the AMI with Amazon EC2 (boolean; true|false;default: false)
# AMI_KERNEL_ID			The ID of the kernel associated with the image e.g. aki-3197c674
# AMI_ARCH				The architecture of the image (type: string; valid values: i386 | x86_64) e.g. i386

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

# Set input defaults (if not set)
#
: ${AMI_ARCH:=}
: ${AMI_REGISTER:=true}
: ${AMI_NAME:=unknown_ami}
: ${AMI_DESCRIPTION:=}
: ${AMI_KERNEL_ID:=}			# 
: ${AMI_RAMDISK_ID:=}			# no ramdisk
: ${AMI_MANIFEST_BUCKET:=}
: ${AMI_MANIFEST:="$AMI_BUNDLE_UPLOAD_S3_BUCKET"/"$AMI_NAME".manifest.xml}
: ${AMI_REGION:=}

[ -e ~/bin/aws-ec2-env.sh ] && source ~/bin/aws-ec2-env.sh

# set local variables for the AMI registration
ami_name=`eval echo $AMI_NAME`
ami_desc=`eval echo $AMI_DESCRIPTION`
ami_region="$AMI_REGION"
ami_arch="$AMI_ARCH"
ami_kernel="$AMI_KERNEL_ID"
ami_ramdisk="$AMI_RAMDISK_ID"
ami_manifest=`eval echo $AMI_MANIFEST`
ami_cert="$AWS_CERT_FILE"
ami_key="$AWS_PRIVATE_KEY_FILE"
if [ "$AMI_ARCH" ]; then
	ami_arch_args='--architecture '"$ami_arch"
fi
if [ "$AMI_KERNEL_ID" ]; then
	ami_kernel_args='--kernel '"$ami_kernel"
fi
if [ "$AMI_RAMDISK_ID" ]; then
	ami_ramdisk_args='--ramdisk '"$ami_ramdisk"
fi

echo 'AMI details:'
echo '--'
echo 'Name:         '"$ami_name"
echo 'Description:  '"$ami_desc"
echo 'Region:       '"$ami_region"
if [ "$ami_arch_args" ]; then
	echo 'Architecture: '"$AMI_ARCH"
else
	echo 'Architecture: not specified'
fi
if [ "$ami_kernel_args" ]; then
	echo 'Kernel:      '"$ami_kernel"
else
	echo 'Kernel:        none'
fi
if [ "$ami_ramdisk_args" ]; then
	echo 'Ramdisk:       '"$ami_kernel"
else
	echo 'Ramdisk:       none'
fi
echo 'Manifest:     '"$ami_manifest"
echo '--'

if [ "$AMI_REGISTER" = 'true' ]; then
	echo 'Registering AMI with Amazon EC2.'
	register_out=$(ec2-register \
		-K "$ami_key" \
		-C "$ami_cert" \
		--name $ami_name \
		--description "$ami_desc" \
		--region $ami_region \
		--block-device-mapping /dev/sdb=ephemeral0 \
		--block-device-mapping /dev/sdc=ephemeral1 \
		--block-device-mapping /dev/sdd=ephemeral2 \
		--block-device-mapping /dev/sde=ephemeral3 \
		$ami_kernel_args $ami_ramdisk_args $ami_arch_args \
	$ami_manifest)
	ami_id=`echo -n $register_out | awk '{ print $2 }'`
	echo "$ami_id"' successfully registered.'
	echo "$ami_id" >> "$TAG_AMI_DB"
	echo 'AMI registered: '"$register_out" | mail -s 'New S3 AMI registered.' "$AMI_REGISTER_NOTIFY_EMAIL"
else
	echo 'AMI_REGISTER is set to false, skipping AMI registration.'
fi

echo 'Done.'