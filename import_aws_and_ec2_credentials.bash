#!/bin/bash -e

# RightScript: Import AWS and EC2 credentials
#
# Description: Imports the AWS and EC2 credentials from the RightScale platform (including the x509 certificate and key).
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

# Create bin, aws creds and ec2 creds profile folders if not existing
[ -e ~/.ec2 ] || mkdir -p ~/.ec2
[ -e ~/.aws ] || mkdir -p ~/.aws
[ -e ~/bin ] || mkdir -p ~/bin

# Save the AWS x509 certificate and key to the aws creds folder when provided
if [ -n "$AWS_X509_CERT" ]; then
	echo 'Install AWS x.509 certificate.'
	echo "$AWS_X509_CERT" > ~/.aws/cert.pem
else
	echo "No AWS x.509 certificate provided, skipping."
fi
if [ -n "$AWS_X509_KEY" ]; then
	echo 'Install AWS x.509 key.'
	echo "$AWS_X509_KEY" > ~/.aws/pk.pem
else
	echo "No AWS x.509 key provided, skipping."
fi

EC2_HOME=/usr/local/ec2

# set java_home and install java if needed on ubuntu
case "$RS_DISTRO" in
	ubuntu)
		# install openjdk-6-jdk if no java installed
		if ! readlink -e /etc/alternatives/java; then
			apt-get -y install openjdk-6-jdk
		fi
		java_bin="$(readlink -e /etc/alternatives/java)"; java_home="${java_bin%/*/*}"
    ;;
	debian)
		java_home=/usr/lib/jvm/default-java
    ;;
	centos)
		java_home=/usr/java/default
	;;
	*)
		java_bin="$(readlink -e /etc/alternatives/java)"; java_home="${java_bin%/*/*}"
	;;
esac

# Create script for exporting AWS and EC2 environment variables
(
cat << EOF
#!/bin/sh -e

export JAVA_HOME="$java_home"

# export ec2 env vars
export EC2_HOME=/usr/local/ec2
export EC2_PRIVATE_KEY=/root/.aws/pk.pem
export EC2_CERT=/root/.aws/cert.pem

# Add export commands for each AWS and EC2 variable/cred
export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
export AWS_ACCOUNT_NUMBER="$AWS_ACCOUNT_NUMBER"

export PATH="$PATH:$EC2_HOME/bin"

EOF
) > ~/bin/aws-ec2-env.sh

# Ensure bin and aws-creds directory is private and set executable on env script
chmod 700 ~/bin/aws-ec2-env.sh
chmod +x ~/bin/aws-ec2-env.sh
chmod -R 700 ~/.aws
chmod -R 700 ~/.ec2

# add to .profile
if ! grep aws-ec2-env.sh ~/.profile > /dev/null 2>&1; then
	echo ". ~/bin/aws-ec2-env.sh" >> ~/.profile
	echo "Added ~/bin/aws-ec2-env.sh to ~/.profile."
fi
if ! grep aws-ec2-env.sh ~/.bashrc > /dev/null 2>&1; then
	echo "source ~/bin/aws-ec2-env.sh" >> ~/.bashrc
	echo "Added ~/bin/aws-ec2-env.sh to ~/.bashrc."
fi

# Inform user that creds can now be sourced in shell
echo 'To import in your sh/bash scripts, use ". ~/bin/aws-ec2-env.sh or source ~/bin/aws-ec2-env.sh"'

chmod -v 700 ~/.profile

echo 'Done.'