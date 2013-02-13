#!/bin/bash -e

# RightScript: Upload Bundled AMI to S3
#
# Description: Upload a bundled AMI to S3.
#
# Inputs:
# AMI_BUNDLE_UPLOAD					Upload the bundled AMI to Amazon S3 storage (boolean; true|false;default: false)
# AMI_BUNDLE_DEST_DIR				
# AMI_BUNDLE_MANIFEST				The path to the manifest file. The manifest file is created during the bundling process and can be found in the directory containing the bundle.
# AMI_BUNDLE_UPLOAD_S3_BUCKET
# AMI_BUNDLE_UPLOAD_S3_BUCKET_LOCATION		
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

# Set input defaults
#
: ${AMI_BUNDLE_UPLOAD:=true}
: ${AMI_BUNDLE_UPLOAD_S3_BUCKET:=}
#: ${AMI_BUNDLE_UPLOAD_S3_BUCKET_LOCATION:=}
: ${AMI_BUNDLE_MANIFEST:=manifest.xml}
: ${AMI_BUNDLE_DEST_DIR:=/ami-bundles}

# source imported aws/ec2 creds
source /root/bin/aws-ec2-env.sh

ec2_bundle_source=`eval echo $AMI_BUNDLE_DEST_DIR`
ec2_bundle_manifest=`eval echo $AMI_BUNDLE_MANIFEST`
ec2_bundle_upload_bucket="$AMI_BUNDLE_UPLOAD_S3_BUCKET"
#ec2_bundle_bucket_location="$AMI_BUNDLE_UPLOAD_S3_BUCKET_LOCATION"

echo
echo 'Bundled AMI details:'
echo '--'
echo 'Source bundle location:   '"$ec2_bundle_source"
echo 'Destination S3 Bucket:    '"$ec2_bundle_upload_bucket"
#echo 'S3 Bucket location:       '"$ec2_bundle_bucket_location"
echo 'Manifest:                 '"$ec2_bundle_manifest"
#echo 'ACL policy:               '
echo '--'
echo

#
# Upload the bundled AMI to Amazon S3 storage
#
if [ "$AMI_BUNDLE_UPLOAD" = 'true' ]; then
	echo 'Uploading bundle to S3 with ec2-upload-vol.'
	ec2-upload-bundle \
	-b "$ec2_bundle_upload_bucket" \
	-m "$ec2_bundle_manifest" \
	-a "$AWS_ACCESS_KEY_ID" \
	-s "$AWS_SECRET_ACCESS_KEY" \
	-d "$ec2_bundle_source" \
	--retry
fi

echo 'Done.'